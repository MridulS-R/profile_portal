class NewsController < ApplicationController
  def index
    @categories = (['general'] + NewsService::CATEGORIES).uniq
    @category = params[:category].presence || 'general'
    @category = 'general' unless @categories.include?(@category)

    # Normalize pagination regardless of data source
    @page_size = (params[:page_size].presence || 12).to_i.clamp(1, 50)
    @page = (params[:page].presence || 1).to_i.clamp(1, 100)

    begin
      service = NewsService.new
      result = service.top_headlines(category: @category, page_size: @page_size, page: @page)
      @articles = result[:articles]
      @total = result[:total]
      # Top stories sections via RSS search
      @top_stories = []
      @top_stories << { title: 'Top in Technology', key: 'technology', articles: service.everything(query: 'technology', page_size: 6) }
      @top_stories << { title: 'Top in Programming', key: 'programming', articles: service.everything(query: 'programming', page_size: 6) }
      @top_stories << { title: 'Top in AI / ML', key: 'ai-ml', articles: service.everything(query: '"artificial intelligence" OR "machine learning" OR AI', page_size: 6) }
    rescue => e
      Rails.logger.error("[NewsController#index] #{e.class}: #{e.message}")
      @articles = []
      @total = 0
      @top_stories = []
      flash.now[:alert] = 'Unable to load news at this time.'
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          category: @category,
          page: @page,
          page_size: @page_size,
          total: @total,
          articles: (@articles || []).map { |a|
            {
              title: a['title'],
              source: infer_source(a),
              image_url: a['urlToImage'] || a['image_url'],
              description: clean_description(a),
              url: a['url'] || a['link'],
              published_at: a['publishedAt'] || a['pubDate']
            }
          },
          top_stories: (@top_stories || []).map { |s|
            {
              title: s[:title],
              key: s[:key],
              articles: (s[:articles] || []).map { |a|
                {
                  title: a['title'],
                  source: infer_source(a),
                  image_url: a['urlToImage'] || a['image_url'],
                  description: clean_description(a),
                  url: a['url'] || a['link'],
                  published_at: a['publishedAt'] || a['pubDate']
                }
              }
            }
          }
        }
      end
    end
  end
  private
  def clean_description(a)
    raw = (a['description'] || a['content']).to_s
    # Skip noisy Google News aggregated lists
    if raw =~ /<(ol|li|a|font)\b/i
      return ''
    end
    txt = ActionView::Base.full_sanitizer.sanitize(raw)
    txt = txt.gsub(/\s+/, ' ').strip
    if txt.length > 240
      cut = txt[0, 240]
      cut = cut[0, (cut.rindex(' ') || cut.length)]
      txt = cut + '…'
    end
    txt
  end

  def infer_source(a)
    src = nil
    begin
      src = a.dig('source', 'name')
    rescue
      src = nil
    end
    src = src.presence || a['source_id']
    title = a['title'].to_s
    if src.blank? || src.to_s.match?(/^news\.google\.com$/i) || src.to_s.strip.casecmp('source').zero?
      if (i = title.rindex(' - ')) && i > 0
        cand = title[(i + 3)..-1].to_s.strip
        src = cand unless cand.empty?
      end
    end
    if src.blank? || src.to_s.match?(/^news\.google\.com$/i)
      u = (a['url'] || a['link']).to_s
      begin
        host = URI.parse(u).host&.sub(/^www\./, '')
        src = host if host.present?
      rescue
      end
    end
    src
  end
end
