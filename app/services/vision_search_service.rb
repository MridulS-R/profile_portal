class VisionSearchService
  # Search persistent pgvector index. Returns { ok: true, results: [...] }
  def self.search(query, k: 5)
    query = query.to_s.strip
    return { ok: false, error: "Please enter a prompt." } if query.blank?

    embedder = Vision.config.embedder
    store = Vision.config.store || Vision::Stores::PgvectorStore.new(dims: Vision.config.dims)

    qv = embedder.embed([query]).first
    results = store.similarity_search(qv, k: k, metric: :cosine)
    { ok: true, results: results }
  rescue => e
    { ok: false, error: e.message }
  end
end
