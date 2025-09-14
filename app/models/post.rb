class Post < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :user

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where.not(published_at: nil) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }

  def publish!
    update!(published_at: Time.current)
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_title?
  end
end

