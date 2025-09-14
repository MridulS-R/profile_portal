class CreateTagsAndPostTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug
      t.timestamps
    end
    add_index :tags, :slug, unique: true
    add_index :tags, :name, unique: true

    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :post_tags, [:post_id, :tag_id], unique: true
  end
end

