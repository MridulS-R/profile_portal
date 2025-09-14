class PostReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    kind = params.require(:kind)
    reaction = @post.reactions.find_or_initialize_by(user: current_user)
    if reaction.persisted? && reaction.kind == kind
      reaction.destroy
    else
      reaction.kind = kind
      reaction.save!
    end
    redirect_to @post
  end

  private
  def set_post
    post_id = params[:post_id] || params[:id]
    @post = Post.friendly.find(post_id)
  end
end
