class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :platform
      t.string :genre
      t.string :status
      t.text :memo
      t.integer :rating
      t.date :purchased_at

      t.timestamps
    end
  end
end
