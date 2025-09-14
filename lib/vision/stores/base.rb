# frozen_string_literal: true

module Vision
  module Stores
    class Base
      attr_reader :dims

      def initialize(dims: Vision.config.dims)
        @dims = dims
      end

      def add(_records)
        raise NotImplementedError
      end

      def similarity_search(_vector, k: 5, metric: :cosine)
        raise NotImplementedError
      end
    end
  end
end

