class AddProfileFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :location, :string
    add_column :users, :skills, :text
    add_column :users, :theme, :string, default: "light"
    add_column :users, :views_count, :integer, default: 0, null: false
  end
end
