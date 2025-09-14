require 'open-uri'
begin
  require 'rss'
rescue LoadError
  # rss gem may not be available; controller should handle empty results gracefully
end
require 'cgi'

class NewsService
  # Supported categories; 'general' falls back to overall Google News RSS
  CATEGORIES = %w[business entertainment general health science sports technology world].freeze

  GOOGLE_BASE = 'https://news.google.com/rss'.freeze

  FEEDS = {
    'general' => [
      GOOGLE_BASE + '?hl=en-US&gl=US&ceid=US:en'
    ],
    'technology' => [
      GOOGLE_BASE + '/headlines/section/topic/TECHNOLOGY?hl=en-US&gl=US&ceid=US:en',
      'https://feeds.arstechnica.com/arstechnica/technology'
    ],
    'science' => [
      GOOGLE_BASE + '/headlines/section/topic/SCIENCE?hl=en-US&gl=US&ceid=US:en',
      'https://www.sciencedaily.com/rss/top/science.xml'
    ],
    'business' => [
      GOOGLE_BASE + '/headlines/section/topic/BUSINESS?hl=en-US&gl=US&ceid=US:en'
    ],
    'health' => [
      GOOGLE_BASE + '/headlines/section/topic/HEALTH?hl=en-US&gl=US&ceid=US:en'
    ],
    'sports' => [
      GOOGLE_BASE + '/headlines/section/topic/SPORTS?hl=en-US&gl=US&ceid=US:en'
    ],
    'entertainment' => [
      GOOGLE_BASE + '/headlines/section/topic/ENTERTAINMENT?hl=en-US&gl=US&ceid=US:en'
    ],
    'world' => [
      GOOGLE_BASE + '/headlines/section/topic/WORLD?hl=en-US&gl=US&ceid=US:en'
    ]
  }.freeze

  USER_AGENT = 'ProfilePortalNews/1.0 (+https://example.com)'.freeze

  def initialize; end

  # Aggregate recent items from category feeds and paginate locally
  def top_headlines(category: 'general', page_size: 20, page: 1, language: 'en')
    category = 'general' unless CATEGORIES.include?(category)
    key = "rssnews:top:#{category}:#{page_size}:#{page}:#{language}"
    items = Rails.cache.fetch(key, expires_in: 5.minutes) do
      urls = FEEDS[category] || FEEDS['general']
      aggregate_feeds(urls, max_items: 200)
    end
    paged = paginate(items, page: page, page_size: page_size)
    { articles: paged, total: items.length }
  rescue => e
    Rails.logger.warn("[NewsService#top_headlines] #{e.class}: #{e.message}")
    { articles: [], total: 0 }
  end

  # Keyword/topic search via Google News RSS search
  def everything(query:, page_size: 10, sort_by: 'publishedAt', language: 'en')
    q = CGI.escape(query.to_s)
    url = GOOGLE_BASE + "/search?q=#{q}&hl=en-US&gl=US&ceid=US:en"
    key = "rssnews:search:#{q}:#{page_size}:#{language}"
    items = Rails.cache.fetch(key, expires_in: 10.minutes) do
      aggregate_feeds([url], max_items: page_size)
    end
    items.first(page_size)
  rescue => e
    Rails.logger.warn("[NewsService#everything] #{e.class}: #{e.message}")
    []
  end

  private
  def aggregate_feeds(urls, max_items: 100)
    return [] unless defined?(RSS)
    items = []
    urls.each do |u|
      begin
        xml = URI.open(u, 'User-Agent' => USER_AGENT, read_timeout: 6, open_timeout: 5).read
        feed = RSS::Parser.parse(xml, false)
        next unless feed && feed.respond_to?(:items)
        feed.items.first(50).each do |it|
          title = safe_title(it)
          link  = safe_link(it)
          desc  = safe_description(it)
          pub   = safe_time(it)
          next if title.blank? || link.blank?
          items << {
            'title' => title,
            'url' => link,
            'link' => link,
            'description' => desc,
            'content' => desc,
            'publishedAt' => pub&.iso8601,
            'pubDate' => pub&.iso8601,
            'source_id' => host_for(link)
          }
        end
      rescue => e
        Rails.logger.info("[NewsService#aggregate_feeds] skip #{u}: #{e.class}: #{e.message}")
        next
      end
    end
    # Sort by published date desc
    items.sort_by { |a| begin Time.parse(a['publishedAt'].to_s) rescue Time.at(0) end }.reverse.first(max_items)
  end

  def paginate(items, page:, page_size:)
    offset = (page - 1) * page_size
    items.slice(offset, page_size) || []
  end

  def safe_title(item)
    (item.respond_to?(:title) ? item.title.to_s : '').strip
  end

  def safe_link(item)
    if item.respond_to?(:link)
      l = item.link
      return l.href.to_s if l.respond_to?(:href)
      return l.to_s if l
    end
    if item.respond_to?(:url)
      return item.url.to_s
    end
    ''
  end

  def safe_description(item)
    if item.respond_to?(:description) && item.description
      return item.description.to_s.strip
    end
    if item.respond_to?(:content_encoded) && item.content_encoded
      return item.content_encoded.to_s.strip
    end
    ''
  end

  def safe_time(item)
    candidates = []
    candidates << item.pubDate if item.respond_to?(:pubDate)
    candidates << item.date if item.respond_to?(:date)
    candidates << item.updated.content if item.respond_to?(:updated) && item.updated.respond_to?(:content)
    candidates << item.published.content if item.respond_to?(:published) && item.published.respond_to?(:content)
    candidates.compact.each do |t|
      ts = t.is_a?(String) ? t : t.to_s
      tm = parse_time(ts)
      return tm if tm
    end
    nil
  end

  def parse_time(str)
    return str if str.is_a?(Time) || str.is_a?(DateTime)
    Time.parse(str.to_s)
  rescue
    nil
  end

  def host_for(url)
    URI.parse(url).host&.sub(/^www\./, '') || 'source'
  rescue
    'source'
  end
end
