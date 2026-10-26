class AddAwardedPlayTimeToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :awarded_play_time, :integer, null: false, default: 0
  end
end
