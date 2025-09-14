class Post < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :user
  belongs_to :category, optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

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

  # Virtual attribute for comma-separated tag names
  def tag_names
    tags.pluck(:name).join(', ')
  end

  def tag_names=(names)
    @tag_names_pending = names.to_s
  end

  after_save :persist_tags

  def rendered_body
    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer,
                                       autolink: true,
                                       tables: true,
                                       fenced_code_blocks: true,
                                       strikethrough: true,
                                       lax_spacing: true,
                                       space_after_headers: true)
    html = markdown.render(self.body.to_s)
    # Sanitize to avoid XSS, allowing common formatting tags
    ActionController::Base.helpers.sanitize(html, tags: %w[p br strong em a ul ol li h1 h2 h3 h4 h5 h6 code pre table thead tbody tr th td blockquote hr], attributes: %w[href rel])
  end

  private
  def persist_tags
    return unless defined?(@tag_names_pending)
    names = @tag_names_pending.split(',').map { |s| s.strip }.reject(&:blank?).uniq
    self.tags = names.map { |n| Tag.where(name: n).first_or_create! }
  ensure
    remove_instance_variable(:@tag_names_pending) rescue nil
  end
end
