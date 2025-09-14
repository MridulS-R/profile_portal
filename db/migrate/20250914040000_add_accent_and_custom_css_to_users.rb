class AddAccentAndCustomCssToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :accent_color, :string
    add_column :users, :custom_css, :text
  end
end

