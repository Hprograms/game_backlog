class CreateUserTrophies < ActiveRecord::Migration[8.0]
  def change
    create_table :user_trophies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trophy, null: false, foreign_key: true
      t.datetime :unlocked_at

      t.timestamps
    end
  end
end
