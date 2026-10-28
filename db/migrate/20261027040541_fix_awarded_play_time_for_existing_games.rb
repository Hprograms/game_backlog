class FixAwardedPlayTimeForExistingGames < ActiveRecord::Migration[8.1]
  def up
    Game.where(awarded_play_time: 0).where.not(play_time: [nil, 0]).find_each do |game|
      game.update_column(:awarded_play_time, game.play_time)
    end
  end

  def down
    # 過去のデータに戻す必要はないため空でOK
  end
end
