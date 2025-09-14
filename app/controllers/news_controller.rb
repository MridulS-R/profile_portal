class NewsController < ApplicationController
  def index
    @categories = ['general'] + NewsService::CATEGORIES
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
    rescue => e
      Rails.logger.error("[NewsController#index] #{e.class}: #{e.message}")
      @articles = []
      flash.now[:alert] = 'Unable to load news at this time.'
    end
  end
end
