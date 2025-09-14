class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end
end

