# frozen_string_literal: true

require_relative "base"
require 'digest/md5'

module Vision
  module Stores
    class PgvectorStore < Base
      def initialize(model: nil, dims: Vision.config.dims)
        super(dims: dims)
        @model = resolve_model(model)
      end

      # records: [{ content:, metadata:, vector:, key: }]
      def add(records)
        return 0 if records.empty?
        now_sql = Arel.sql('NOW()')
        inserted = 0
        records.each_slice(100) do |batch|
          values_sql = batch.map do |r|
            key = r[:key].to_s
            content = r[:content].to_s
            metadata = (r[:metadata] || {}).to_json
            vec_lit = vector_sql_literal(r[:vector])
            # Use bound parameters for content/metadata, direct literal for vector
            # We'll build a VALUES list with sanitized strings
            "(#{@model.connection.quote(key)}, #{@model.connection.quote(content)}, #{@model.connection.quote(metadata)}::jsonb, #{vec_lit}, NOW(), NOW())"
          end.join(", ")
          sql = <<~SQL
            INSERT INTO vision_vectors (key, content, metadata, embedding, created_at, updated_at)
            VALUES #{values_sql}
            ON CONFLICT (key) DO UPDATE
            SET content = EXCLUDED.content,
                metadata = EXCLUDED.metadata,
                embedding = EXCLUDED.embedding,
                updated_at = NOW();
          SQL
          @model.connection.execute(sql)
          inserted += batch.length
        end
        inserted
      end

      def similarity_search(vector, k: 5, metric: :cosine)
        k = [[k.to_i, 1].max, 1000].min
        vec_lit = vector_sql_literal(vector)
        order_expr = case metric
                     when :cosine then "embedding <=> #{vec_lit}"
                     when :l2 then "embedding <-> #{vec_lit}"
                     when :dot then "embedding <#> #{vec_lit}"
                     else "embedding <=> #{vec_lit}"
                     end
        sql = <<~SQL
          SELECT content, metadata, #{similarity_sql(metric, vec_lit)} AS score
          FROM vision_vectors
          ORDER BY #{order_expr} ASC
          LIMIT #{k}
        SQL
        rows = @model.connection.exec_query(sql)
        rows.map do |row|
          {
            content: row["content"],
            metadata: row["metadata"].is_a?(String) ? JSON.parse(row["metadata"]) : row["metadata"],
            score: row["score"].to_f
          }
        end
      end

      private
      def resolve_model(model)
        return model if model
        # Try to load app model if not already loaded
        begin
          if defined?(::VectorRecord)
            ::VectorRecord
          else
            require_dependency Rails.root.join('app/models/vector_record').to_s
            ::VectorRecord
          end
        rescue NameError, LoadError
          # Fallback to using the base connection; table can still be accessed via raw SQL.
          ActiveRecord::Base
        end
      end

      def vector_sql_literal(vec)
        vals = Array(vec).map { |x| format('%.6f', x.to_f) }.join(',')
        "'[#{vals}]'"
      end

      def similarity_sql(metric, vec_lit)
        case metric
        when :cosine
          # cosine distance = 1 - cosine similarity
          "(1 - (embedding <=> #{vec_lit}))"
        when :l2
          # negative distance as score
          "(- (embedding <-> #{vec_lit}))"
        when :dot
          # higher dot product is better; negate distance operator result if needed
          "(- (embedding <#> #{vec_lit}))"
        else
          "(1 - (embedding <=> #{vec_lit}))"
        end
      end
    end
  end
end
