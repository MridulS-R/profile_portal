class NewsController < ApplicationController
  def index
    @categories = (['general'] + NewsService::CATEGORIES).uniq
    @category = params[:category].presence || 'general'
    @category = 'general' unless @categories.include?(@category)

    if ENV['NEWSAPI_KEY'].blank?
      @articles = []
      flash.now[:alert] = 'NEWSAPI_KEY is not configured; cannot load news.'
      return
    end

    begin
      service = NewsService.new
      @page_size = (params[:page_size].presence || 12).to_i.clamp(1, 50)
      @page = (params[:page].presence || 1).to_i.clamp(1, 100)
      result = service.top_headlines(category: @category, page_size: @page_size, page: @page)
      @articles = result[:articles]
      @total = result[:total]
      # Top stories sections
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
              source: a.dig('source', 'name'),
              image_url: a['urlToImage'],
              description: a['description'],
              url: a['url'],
              published_at: a['publishedAt']
            }
          },
          top_stories: (@top_stories || []).map { |s|
            {
              title: s[:title],
              key: s[:key],
              articles: (s[:articles] || []).map { |a|
                {
                  title: a['title'],
                  source: a.dig('source', 'name'),
                  image_url: a['urlToImage'],
                  description: a['description'],
                  url: a['url'],
                  published_at: a['publishedAt']
                }
              }
            }
          }
        }
      end
    end
  end
end
