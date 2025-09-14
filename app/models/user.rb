
class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :google_oauth2]

  has_many :projects, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_one_attached :resume

  validate :validate_resume

  validates :name, presence: true

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end

  def resume_pdf?
    resume.attached? && resume.blob&.content_type == 'application/pdf'
  end

  private
  def validate_resume
    return unless resume.attached?
    allowed = %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document]
    unless allowed.include?(resume.blob.content_type)
      errors.add(:resume, 'must be a PDF or Word document')
    end
    max_bytes = 10.megabytes
    if resume.blob.byte_size > max_bytes
      errors.add(:resume, 'size must be under 10 MB')
    end
  end
end
