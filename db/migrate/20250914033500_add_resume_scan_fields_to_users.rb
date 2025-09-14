class AddResumeScanFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :resume_scan_status, :string, default: 'pending'
    add_column :users, :resume_virus_found, :boolean, default: false, null: false
  end
end

