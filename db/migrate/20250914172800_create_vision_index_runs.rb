# frozen_string_literal: true

class CreateVisionIndexRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :vision_index_runs do |t|
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :records_indexed, default: 0, null: false
      t.boolean :success, default: false, null: false
      t.text :error
      t.timestamps
    end
  end
end

