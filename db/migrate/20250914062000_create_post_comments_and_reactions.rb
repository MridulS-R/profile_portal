class CreatePostCommentsAndReactions < ActiveRecord::Migration[7.1]
  def change
    create_table :post_comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end

    create_table :post_reactions do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false # 'like' or 'dislike'
      t.timestamps
    end
    add_index :post_reactions, [:post_id, :user_id], unique: true

    add_column :users, :allow_comments, :boolean, default: true, null: false
  end
end

