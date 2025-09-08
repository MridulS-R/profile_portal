
class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github]

  has_many :projects, dependent: :destroy
  has_many :domains, dependent: :destroy

  validates :name, presence: true

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end
end
