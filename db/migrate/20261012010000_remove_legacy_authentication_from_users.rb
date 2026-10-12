class RemoveLegacyAuthenticationFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :reset_password_token
    remove_column :users, :encrypted_password, :string, default: "", null: false
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
    remove_column :users, :activation_digest, :string
    remove_column :users, :activated, :boolean, default: false
    remove_column :users, :activated_at, :datetime
  end
end
