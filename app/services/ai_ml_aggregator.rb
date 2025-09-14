begin
  require 'rss'
rescue LoadError
  # rss gem not available; RSS fallback will be disabled
end
require 'time'
require 'open-uri'

class AiMlAggregator
  FEEDS = [
    # Reliable AI/ML related feeds
    'https://ai.googleblog.com/feeds/posts/default',
    'https://deepmind.google/discover/blog/rss',
    'https://huggingface.co/blog/rss.xml',
    'https://www.kdnuggets.com/feed',
    'http://export.arxiv.org/rss/cs.LG'
  ].freeze

  USER_AGENT = "ProfilePortalBot/1.0 (+https://example.com)".freeze

  Article = Struct.new(:title, :url, :source, :published_at, keyword_init: true)

  class << self
    def fetch_top(limit: 10)
      Rails.cache.fetch(cache_key(limit), expires_in: 1.hour) do
        via_news_api(limit) || via_rss(limit)
      end
    rescue => e
      Rails.logger.warn("[AiMlAggregator] #{e.class}: #{e.message}")
      []
    end

    private

    def cache_key(limit)
      "ai_ml:top:#{limit}"
    end

    # Prefer NewsAPI if configured
    def via_news_api(limit)
      api_key = ENV['NEWSAPI_KEY']
      return nil if api_key.blank?

      begin
        svc = NewsService.new(api_key: api_key)
        # Broad query for AI/ML topics
        query = '("artificial intelligence" OR AI OR "machine learning" OR "deep learning")'
        articles = svc.everything(query: query, page_size: limit, sort_by: 'publishedAt', language: 'en')
        return nil if articles.blank?

        articles.filter_map do |a|
          title = a['title'].to_s.strip
          url   = a['url'].to_s
          next if title.empty? || url.empty?
          source = (a.dig('source', 'name') || host_for(url)).to_s
          published = parse_time(a['publishedAt'])
          Article.new(title: title, url: url, source: source, published_at: published)
        end
      rescue => e
        Rails.logger.info("[AiMlAggregator#via_news_api] fallback: #{e.class}: #{e.message}")
        nil
      end
    end

    def via_rss(limit)
      return [] unless defined?(RSS) && defined?(RSS::Parser)
      items = []
      FEEDS.each do |url|
        begin
          xml = URI.open(url, 'User-Agent' => USER_AGENT, read_timeout: 6, open_timeout: 5).read
          feed = RSS::Parser.parse(xml, false)
          next unless feed && feed.respond_to?(:items)

          feed.items.first(25).each do |it|
            title = safe_title(it)
            link  = safe_link(it)
            pub   = safe_time(it)
            next if title.blank? || link.blank?
            items << Article.new(title: title, url: link, source: host_for(link), published_at: pub)
          end
        rescue => e
          Rails.logger.info("[AiMlAggregator#via_rss] skip #{url}: #{e.class}: #{e.message}")
          next
        end
      end

      items = items.sort_by { |a| a.published_at || Time.at(0) }.reverse
      items.first(limit)
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
end
