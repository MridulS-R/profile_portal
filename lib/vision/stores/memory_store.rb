# frozen_string_literal: true

require_relative "base"

module Vision
  module Stores
    class MemoryStore < Base
      def initialize(dims: Vision.config.dims)
        super(dims: dims)
        @data = []
      end

      # records: array of {content:, metadata:, vector:}
      def add(records)
        records.each do |r|
          next unless r[:vector]&.length == @dims
          @data << { content: r[:content], metadata: r[:metadata] || {}, vector: r[:vector] }
        end
        @data.length
      end

      # vector: array of floats; returns array of {content:, metadata:, score:}
      def similarity_search(vector, k: 5, metric: :cosine)
        score_fn = case metric
                   when :cosine then ->(a, b) { Utils.cosine_similarity(a, b) }
                   when :dot then ->(a, b) { Utils.dot_product(a, b) }
                   when :l2 then ->(a, b) { -Utils.l2_distance(a, b) } # invert for ranking
                   else ->(a, b) { Utils.cosine_similarity(a, b) }
                   end
        @data.map do |rec|
          { content: rec[:content], metadata: rec[:metadata], score: score_fn.call(vector, rec[:vector]) }
        end.sort_by { |h| -h[:score] }.first(k)
      end

      def delete_by_path(path)
        before = @data.length
        @data.delete_if do |rec|
          meta = rec[:metadata] || {}
          (meta[:path] || meta["path"]) == path
        end
        before - @data.length
      end
    end
  end
end

