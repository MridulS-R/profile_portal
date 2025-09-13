class AddVerificationToDomains < ActiveRecord::Migration[7.1]
  def change
    add_column :domains, :verification_token, :string
    add_column :domains, :verified_at, :datetime
    add_index :domains, :verification_token, unique: true
  end
end
