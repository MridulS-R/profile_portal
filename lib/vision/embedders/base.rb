# frozen_string_literal: true

module Vision
  module Embedders
    class Base
      attr_reader :dims
      def initialize(dims: Vision.config.dims)
        @dims = dims
      end

      # texts: array of strings -> returns array of vectors
      def embed(_texts)
        raise NotImplementedError
      end
    end
  end
end

