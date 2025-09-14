class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show]
  before_action :set_owned_post, only: [:edit, :update, :destroy]

  def index
    # Determine which user sidebar to show (domain user → site owner → current user → first)
    @user = @domain_user || site_owner || current_user || User.first
    @posts = []
    begin
      scope = Post.published.recent.includes(:user, :tags, :category)
      if params[:tag].present?
        begin
          @tag = Tag.friendly.find(params[:tag])
          scope = scope.joins(:tags).where(tags: { id: @tag.id }) if @tag
        rescue StandardError
          @tag = nil
        end
      end
      if params[:category].present?
        begin
          @category = Category.friendly.find(params[:category])
          scope = scope.where(category: @category) if @category
        rescue StandardError
          @category = nil
        end
      end
      @posts = scope
    rescue ActiveRecord::StatementInvalid, NameError => e
      Rails.logger.error("[PostsController#index] #{e.class}: #{e.message}")
      flash.now[:alert] = 'Blog is initializing or unavailable. Please ensure migrations have run.'
      @posts = []
    end
  end

  def show; end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.published_at ||= Time.current
    if @post.save
      redirect_to @post, notice: "Post published"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted"
  end

  private
  def set_post
    @post = Post.friendly.find(params[:id])
  rescue StandardError => e
    Rails.logger.error("[PostsController#set_post] #{e.class}: #{e.message}")
    redirect_to posts_path, alert: 'Post not found.'
  end

  def set_owned_post
    @post = current_user.posts.friendly.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published_at, :category_id, :tag_names)
  end

  def site_owner
    gh = ENV["SITE_OWNER_GITHUB"].presence
    gh && User.find_by(github_username: gh)
  end
end
