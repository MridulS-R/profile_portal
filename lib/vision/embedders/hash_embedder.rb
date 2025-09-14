# frozen_string_literal: true

require_relative "base"
require 'zlib'

module Vision
  module Embedders
    # Deterministic, dependency-free embedder using hashed token features.
    # Not semantically strong, but consistent across runs and suitable for demos.
    class HashEmbedder < Base
      def initialize(dims: Vision.config.dims)
        super(dims: dims)
      end

      def embed(texts)
        texts.map { |t| embed_one(t.to_s) }
      end

      private
      def embed_one(text)
        vec = Array.new(@dims, 0.0)
        tokens = tokenize(text)
        tokens.each do |tok|
          h = Zlib.crc32(tok)
          idx = h % @dims
          sign = ((h >> 1) & 1) == 0 ? 1.0 : -1.0
          vec[idx] += sign
        end
        # L2 normalize
        norm = Math.sqrt(vec.map { |x| x * x }.sum)
        return vec if norm.zero?
        vec.map { |x| x / norm }
      end

      def tokenize(text)
        text.downcase.scan(/[\p{L}\p{N}_]+/u)
      end
    end
  end
end

