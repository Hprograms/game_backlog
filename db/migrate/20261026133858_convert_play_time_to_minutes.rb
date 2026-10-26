class ConvertPlayTimeToMinutes < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE games SET play_time = play_time * 60 WHERE play_time IS NOT NULL"
    execute "UPDATE games SET awarded_play_time = awarded_play_time * 60"
  end

  def down
    execute "UPDATE games SET play_time = play_time / 60 WHERE play_time IS NOT NULL"
    execute "UPDATE games SET awarded_play_time = awarded_play_time / 60"
  end
end
