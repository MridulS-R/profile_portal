class PostCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    unless @post.user.allow_comments?
      redirect_to @post, alert: 'Comments are disabled by the author.' and return
    end
    comment = @post.comments.build(body: params.require(:post_comment)[:body], user: current_user)
    if comment.save
      redirect_to @post, notice: 'Comment posted'
    else
      redirect_to @post, alert: 'Comment cannot be blank'
    end
  end

  def destroy
    comment = @post.comments.find(params[:id])
    unless comment.user_id == current_user.id || @post.user_id == current_user.id
      redirect_to @post, alert: 'Not authorized' and return
    end
    comment.destroy
    redirect_to @post, notice: 'Comment deleted'
  end

  private
  def set_post
    @post = Post.friendly.find(params[:post_id])
  end
end

