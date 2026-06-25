class AddPlayDetailsToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :play_time, :integer
    add_column :games, :played_at, :date
  end
end
