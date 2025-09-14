class LlmController < ApplicationController
  before_action :require_admin!, only: [:reindex, :status]
  def new
    @prompt = ""
    @results = []
    @error  = nil
  end

  def create
    @prompt = params[:prompt].to_s.strip
    @k = params[:k].presence&.to_i || 5
    result = VisionSearchService.search(@prompt, k: @k)
    if result[:ok]
      @results = result[:results]
      @error = nil
    else
      @results = []
      @error = result[:error]
    end
    render :new
  end

  def reindex
    VisionIndexJob.perform_later
    flash[:notice] = "Reindex enqueued. It will refresh in the background."
    redirect_to llm_path
  end

  def status
    @runs = VisionIndexRun.order(created_at: :desc).limit(20)
  end
end
