class AddPlayPeriodToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :started_at, :date
    add_column :games, :finished_at, :date
  end
end
