class ReplaceRawgMetadataWithIgdbRating < ActiveRecord::Migration[8.0]
  def up
    remove_column :games, :average_playtime, :integer if column_exists?(:games, :average_playtime)
    remove_column :games, :metascore if column_exists?(:games, :metascore)
    add_column :games, :igdb_rating, :integer unless column_exists?(:games, :igdb_rating)
    add_column :games, :developer, :string unless column_exists?(:games, :developer)
    add_column :games, :description, :text unless column_exists?(:games, :description)
  end

  def down
    remove_column :games, :igdb_rating if column_exists?(:games, :igdb_rating)
    add_column :games, :metascore, :integer unless column_exists?(:games, :metascore)
    add_column :games, :average_playtime, :integer unless column_exists?(:games, :average_playtime)
  end
end