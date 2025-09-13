class AdjustProjectsUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    if index_exists?(:projects, :repo_full_name, unique: true)
      remove_index :projects, column: :repo_full_name
    end
    add_index :projects, [:user_id, :repo_full_name], unique: true unless index_exists?(:projects, [:user_id, :repo_full_name], unique: true)
  end
end

