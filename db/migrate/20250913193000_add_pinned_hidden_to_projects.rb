class AddPinnedHiddenToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :pinned, :boolean, default: false, null: false
    add_column :projects, :hidden, :boolean, default: false, null: false
  end
end

