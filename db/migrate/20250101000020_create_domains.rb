
class CreateDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :domains do |t|
      t.string :host, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :domains, :host, unique: true
  end
end
