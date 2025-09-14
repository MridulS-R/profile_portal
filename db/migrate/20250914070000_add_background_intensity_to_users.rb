class AddBackgroundIntensityToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :background_intensity, :string, default: 'medium'
  end
end

