
class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :repo_full_name
      t.string :html_url
      t.text :description
      t.string :language
      t.integer :stars
      t.integer :forks
      t.integer :open_issues
      t.text :topics
      t.string :homepage
      t.datetime :pushed_at
      t.datetime :fetched_at
      t.timestamps
    end
    add_index :projects, :repo_full_name, unique: true
  end
end
