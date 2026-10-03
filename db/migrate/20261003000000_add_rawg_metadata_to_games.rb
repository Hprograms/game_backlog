class AddRawgMetadataToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :metascore, :integer
    add_column :games, :average_playtime, :integer
  end
end