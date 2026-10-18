class CreateTrophies < ActiveRecord::Migration[8.0]
  def change
    create_table :trophies do |t|
      t.string :name
      t.string :description
      t.string :icon_name

      t.timestamps
    end
  end
end
