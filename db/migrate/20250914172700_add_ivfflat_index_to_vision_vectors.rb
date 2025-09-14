# frozen_string_literal: true

class AddIvfflatIndexToVisionVectors < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_vision_vectors_on_embedding_cosine
      ON vision_vectors USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS index_vision_vectors_on_embedding_cosine;
    SQL
  end
end

