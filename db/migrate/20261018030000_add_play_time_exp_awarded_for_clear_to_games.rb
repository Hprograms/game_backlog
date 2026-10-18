class AddPlayTimeExpAwardedForClearToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :play_time_exp_awarded_for_clear, :boolean, default: false, null: false

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE games
          SET play_time_exp_awarded_for_clear = TRUE
          WHERE exp_awarded_for_clear = TRUE AND play_time IS NOT NULL
        SQL
      end
    end
  end
end
