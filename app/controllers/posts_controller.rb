class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show]
  before_action :set_owned_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.recent.includes(:user, :tags, :category)
    if params[:tag].present?
      @tag = Tag.friendly.find(params[:tag]) rescue nil
      @posts = @posts.joins(:tags).where(tags: { id: @tag.id }) if @tag
    end
    if params[:category].present?
      @category = Category.friendly.find(params[:category]) rescue nil
      @posts = @posts.where(category: @category) if @category
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
  end

  def set_owned_post
    @post = current_user.posts.friendly.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published_at, :category_id, :tag_names)
  end
end
