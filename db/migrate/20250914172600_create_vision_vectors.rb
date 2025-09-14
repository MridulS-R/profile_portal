# frozen_string_literal: true

class CreateVisionVectors < ActiveRecord::Migration[7.1]
  def change
    create_table :vision_vectors do |t|
      t.string :key, null: false
      t.text :content, null: false
      t.jsonb :metadata, null: false, default: {}
      # Use raw SQL for vector column to avoid gem dependency
    end

    # Add vector column with dimension 384
    execute <<~SQL
      ALTER TABLE vision_vectors
      ADD COLUMN embedding vector(384) NOT NULL;
    SQL

    add_index :vision_vectors, :key, unique: true
    add_index :vision_vectors, :metadata, using: :gin

    # Timestamps separate to avoid vector gem requirement
    add_column :vision_vectors, :created_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    add_column :vision_vectors, :updated_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end

