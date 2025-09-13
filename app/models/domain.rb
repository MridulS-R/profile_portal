
class Domain < ApplicationRecord
  belongs_to :user
  validates :host, presence: true, uniqueness: true

  before_create :set_verification_token

  def verified?
    verified_at.present?
  end

  private

  def set_verification_token
    self.verification_token ||= SecureRandom.hex(8)
  end
end
