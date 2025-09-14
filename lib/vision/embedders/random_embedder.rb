# frozen_string_literal: true

require_relative "base"

module Vision
  module Embedders
    class RandomEmbedder < Base
      def initialize(dims: Vision.config.dims, seed: 1234)
        super(dims: dims)
        @rng = Random.new(seed)
      end

      def embed(texts)
        texts.map do |_t|
          v = Array.new(@dims) { (@rng.rand - 0.5) * 2.0 }
          norm = Math.sqrt(v.map { |x| x * x }.sum)
          norm.zero? ? v : v.map { |x| x / norm }
        end
      end
    end
  end
end

