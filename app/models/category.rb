class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :posts

  validates :name, presence: true, uniqueness: true

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end
end

