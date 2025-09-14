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
      @articles = service.top_headlines(category: @category)
      # Top stories sections
      @top_stories = []
      @top_stories << { title: 'Top in Technology', key: 'technology', articles: service.everything(query: 'technology', page_size: 6) }
      @top_stories << { title: 'Top in Programming', key: 'programming', articles: service.everything(query: 'programming', page_size: 6) }
      @top_stories << { title: 'Top in AI / ML', key: 'ai-ml', articles: service.everything(query: '"artificial intelligence" OR "machine learning" OR AI', page_size: 6) }
    rescue => e
      Rails.logger.error("[NewsController#index] #{e.class}: #{e.message}")
      @articles = []
      @top_stories = []
      flash.now[:alert] = 'Unable to load news at this time.'
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          category: @category,
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
