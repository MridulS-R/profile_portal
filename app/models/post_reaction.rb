class PostReaction < ApplicationRecord
  KINDS = %w[like dislike]

  belongs_to :post
  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :user_id, uniqueness: { scope: :post_id }
end

