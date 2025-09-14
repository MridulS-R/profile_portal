# frozen_string_literal: true

require "logger"

module Vision
  autoload :VERSION, "vision/version"
  autoload :Config, "vision/config"
  autoload :Utils, "vision/utils"

  module Embedders
    autoload :Base, "vision/embedders/base"
    autoload :RandomEmbedder, "vision/embedders/random_embedder"
    autoload :HashEmbedder, "vision/embedders/hash_embedder"
  end

  module Stores
    autoload :Base, "vision/stores/base"
    autoload :MemoryStore, "vision/stores/memory_store"
    autoload :PgvectorStore, "vision/stores/pgvector_store"
  end

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end

    def logger
      config.logger
    end

    # Convenience search using configured store and embedder
    def search(query, k: 5, metric: :cosine)
      embedder = config.embedder || raise("No embedder configured")
      store = config.store || raise("No store configured")
      vector = embedder.embed([query]).first
      store.similarity_search(vector, k: k, metric: metric)
    end
  end
end
