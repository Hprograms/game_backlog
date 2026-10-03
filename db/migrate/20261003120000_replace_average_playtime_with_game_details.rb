class ReplaceAveragePlaytimeWithGameDetails < ActiveRecord::Migration[8.0]
  def change
    remove_column :games, :average_playtime, :integer
    add_column :games, :developer, :string
    add_column :games, :description, :text
  end
end