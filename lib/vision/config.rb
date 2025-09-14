# frozen_string_literal: true

require "logger"

module Vision
  class Config
    attr_accessor :dims, :embedder, :store, :logger,
                  :batch_size, :max_retries, :retry_backoff

    def initialize
      @dims = 384
      @embedder = nil
      @store = Stores::MemoryStore.new(dims: @dims)
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
      @batch_size = 64
      @max_retries = 3
      @retry_backoff = 0.5
    end
  end
end

