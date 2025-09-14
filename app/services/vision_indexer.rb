# frozen_string_literal: true

class VisionIndexer
  # Gathers content from posts, projects, profiles, resumes, and static docs,
  # embeds them, and persists vectors in Postgres via Vision::Stores::PgvectorStore.
  def self.index_all
    embedder = Vision.config.embedder
    store = Vision.config.store || Vision::Stores::PgvectorStore.new(dims: Vision.config.dims)

    docs = []
    docs.concat load_posts
    docs.concat load_projects
    docs.concat load_profiles
    docs.concat load_resumes
    docs.concat load_static_docs

    return 0 if docs.empty?

    # Embed and persist in batches
    texts = docs.map { |d| d[:content].to_s }
    vectors = embedder.embed(texts)
    to_store = docs.each_with_index.map do |d, i|
      { key: d[:key], content: d[:content], metadata: d[:metadata], vector: vectors[i] }
    end
    store.add(to_store)
  end

  def self.load_posts
    arr = []
    return arr unless defined?(Post)
    Post.published.recent.limit(1000).includes(:category).each do |p|
      content = [p.title.to_s, p.body.to_s].join("\n\n")
      arr << { key: "post:#{p.id}", content: content, metadata: { type: 'post', id: p.id, slug: p.slug, title: p.title, category: p.category&.name } }
    end
    arr
  rescue => e
    Rails.logger.warn("[VisionIndexer] posts: #{e.class}: #{e.message}")
    arr
  end

  def self.load_projects
    arr = []
    return arr unless defined?(Project)
    Project.order(pushed_at: :desc).limit(1000).each do |pr|
      content = [pr.repo_full_name.to_s, pr.description.to_s, Array(pr.topics).join(', ')].join("\n\n")
      arr << { key: "project:#{pr.id}", content: content, metadata: { type: 'project', id: pr.id, repo: pr.repo_full_name } }
    end
    arr
  rescue => e
    Rails.logger.warn("[VisionIndexer] projects: #{e.class}: #{e.message}")
    arr
  end

  def self.load_profiles
    arr = []
    return arr unless defined?(User)
    User.find_each do |u|
      pieces = [u.name, u.bio, u.location, u.skills, u.education, u.experience, u.website].compact.map(&:to_s)
      next if pieces.join.strip.blank?
      content = pieces.join("\n\n")
      arr << { key: "user:#{u.id}", content: content, metadata: { type: 'user', id: u.id, slug: u.slug, name: u.name } }
    end
    arr
  rescue => e
    Rails.logger.warn("[VisionIndexer] profiles: #{e.class}: #{e.message}")
    arr
  end

  def self.load_resumes
    arr = []
    return arr unless defined?(User)
    begin
      require 'pdf/reader'
    rescue LoadError
      Rails.logger.info("[VisionIndexer] pdf-reader not installed; skipping resume extraction")
      # continue to attempt docx extraction if available
    end
    User.includes(resume_attachment: :blob).find_each do |u|
      next unless u.resume.attached?
      blob = u.resume.blob
      text = nil
      if blob.content_type == 'application/pdf'
        text = defined?(PDF::Reader) ? extract_pdf_text(blob) : nil
      elsif blob.content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        text = extract_docx_text(blob)
      end
      next if text.blank?
      arr << { key: "resume:#{u.id}", content: text, metadata: { type: 'resume', id: u.id, slug: u.slug, name: u.name, filename: blob.filename.to_s } }
    end
    arr
  rescue => e
    Rails.logger.warn("[VisionIndexer] resumes: #{e.class}: #{e.message}")
    arr
  end

  def self.extract_pdf_text(blob)
    io = StringIO.new(blob.download)
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.warn("[VisionIndexer] PDF extract failed: #{e.class}: #{e.message}")
    nil
  end

  def self.load_static_docs
    arr = []
    # README.md
    readme = Rails.root.join('README.md')
    if File.exist?(readme)
      arr << { key: "file:README.md", content: File.read(readme), metadata: { type: 'file', path: 'README.md' } }
    end
    Dir.glob(Rails.root.join('docs/**/*.{md,txt}')).each do |path|
      rel = Pathname.new(path).relative_path_from(Rails.root).to_s
      arr << { key: "file:#{rel}", content: File.read(path), metadata: { type: 'file', path: rel } }
    end
    # Public HTML: strip tags to plain text
    Dir.glob(Rails.root.join('public/**/*.html')).each do |path|
      rel = Pathname.new(path).relative_path_from(Rails.root).to_s
      html = File.read(path)
      text = strip_html(html)
      next if text.to_s.strip.blank?
      arr << { key: "file:#{rel}", content: text, metadata: { type: 'file', path: rel } }
    end
    arr
  rescue => e
    Rails.logger.warn("[VisionIndexer] static docs: #{e.class}: #{e.message}")
    arr
  end

  def self.extract_docx_text(blob)
    begin
      require 'zip'
    rescue LoadError
      begin
        require 'rubyzip'
      rescue LoadError
        Rails.logger.info("[VisionIndexer] rubyzip not installed; skipping DOCX extraction")
        return nil
      end
    end
    data = blob.download
    text = nil
    Zip::File.open_buffer(StringIO.new(data)) do |zip|
      entry = zip.glob('word/document.xml').first
      return nil unless entry
      xml = entry.get_input_stream.read
      # Naive tag stripping for DOCX XML
      text = xml.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
    end
    text
  rescue => e
    Rails.logger.warn("[VisionIndexer] DOCX extract failed: #{e.class}: #{e.message}")
    nil
  end

  def self.strip_html(html)
    begin
      ActionController::Base.helpers.strip_tags(html.to_s)
    rescue
      html.to_s.gsub(/<[^>]+>/, ' ')
    end
  end
end
