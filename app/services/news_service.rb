class NewsService
  CATEGORIES = %w[business entertainment general health science sports technology].freeze
  DEFAULT_COUNTRY = ENV.fetch('NEWSAPI_COUNTRY', 'us')

  def initialize(api_key: ENV['NEWSAPI_KEY'])
    @api_key = api_key
    @conn = Faraday.new(url: 'https://newsapi.org/v2') do |f|
      f.request :retry, max: 2, interval: 0.1, backoff_factor: 2
      f.adapter Faraday.default_adapter
    end
  end

  def top_headlines(category: 'general', country: DEFAULT_COUNTRY, page_size: 20)
    raise ArgumentError, 'Missing NEWSAPI_KEY' if @api_key.blank?
    category = 'general' unless CATEGORIES.include?(category) || category == 'general'
    key = "newsapi:top:#{country}:#{category}:#{page_size}"
    Rails.cache.fetch(key, expires_in: 5.minutes) do
      resp = @conn.get('top-headlines', { country: country, category: category, pageSize: page_size }, { 'X-Api-Key' => @api_key })
      data = JSON.parse(resp.body) rescue { 'status' => 'error', 'articles' => [] }
      if data['status'] == 'ok'
        data['articles'] || []
      else
        []
      end
    end
  rescue Faraday::Error => e
    Rails.logger.warn("[NewsService] #{e.class}: #{e.message}")
    []
  end
end

