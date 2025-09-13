
class Domain < ApplicationRecord
  belongs_to :user
  validates :host, presence: true, uniqueness: true

  before_create :set_verification_token

  def verified?
    has_attribute?(:verified_at) ? verified_at.present? : false
  end

  private

  def set_verification_token
    if has_attribute?(:verification_token)
      self.verification_token ||= SecureRandom.hex(8)
    end
  end
end
