class AddThemeAndCustomCssToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :theme, :string, default: "light", null: false
    add_column :users, :custom_css, :text
  end
end

