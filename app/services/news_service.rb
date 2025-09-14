begin
  require 'faraday/retry'
rescue LoadError
  # faraday-retry not available; connection will be created without retry middleware
end

class NewsService
  CATEGORIES = %w[business entertainment general health science sports technology].freeze
  DEFAULT_COUNTRY = ENV.fetch('NEWSAPI_COUNTRY', 'us')

  def initialize(api_key: ENV['NEWSAPI_KEY'])
    @api_key = api_key
    @conn = Faraday.new(url: 'https://newsapi.org/v2') do |f|
      f.request :retry, max: 2, interval: 0.1, backoff_factor: 2 if defined?(Faraday::Retry)
      f.adapter Faraday.default_adapter
    end
  end

  def top_headlines(category: 'general', country: DEFAULT_COUNTRY, page_size: 20, page: 1)
    raise ArgumentError, 'Missing NEWSAPI_KEY' if @api_key.blank?
    category = 'general' unless CATEGORIES.include?(category) || category == 'general'
    key = "newsapi:top:#{country}:#{category}:#{page_size}:#{page}"
    Rails.cache.fetch(key, expires_in: 5.minutes) do
      resp = @conn.get('top-headlines', { country: country, category: category, pageSize: page_size, page: page }, { 'X-Api-Key' => @api_key })
      data = JSON.parse(resp.body) rescue { 'status' => 'error', 'articles' => [] }
      return { articles: [], total: 0 } unless data['status'] == 'ok'
      { articles: (data['articles'] || []), total: (data['totalResults'] || 0) }
    end
  rescue Faraday::Error => e
    Rails.logger.warn("[NewsService] #{e.class}: #{e.message}")
    { articles: [], total: 0 }
  end

  # Everything endpoint for keyword/topic searches
  def everything(query:, page_size: 10, sort_by: 'publishedAt', language: 'en')
    raise ArgumentError, 'Missing NEWSAPI_KEY' if @api_key.blank?
    key = "newsapi:everything:#{query}:#{page_size}:#{sort_by}:#{language}"
    Rails.cache.fetch(key, expires_in: 10.minutes) do
      resp = @conn.get('everything', { q: query, pageSize: page_size, sortBy: sort_by, language: language }, { 'X-Api-Key' => @api_key })
      data = JSON.parse(resp.body) rescue { 'status' => 'error', 'articles' => [] }
      data['status'] == 'ok' ? (data['articles'] || []) : []
    end
  rescue Faraday::Error => e
    Rails.logger.warn("[NewsService#everything] #{e.class}: #{e.message}")
    []
  end
end
