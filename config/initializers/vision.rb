# frozen_string_literal: true

require "vision"

Vision.configure do |c|
  c.dims = 384
  # Deterministic local embedder (no network)
  c.embedder = Vision::Embedders::HashEmbedder.new(dims: c.dims)
  # Persist vectors in Postgres (pgvector)
  c.store = Vision::Stores::PgvectorStore.new(dims: c.dims)
  c.logger.level = Logger::WARN
end
