# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

trophies = [
  { code: "level_10", name: "冒険の始まり", description: "レベル10に到達した証", icon_name: "military_tech" },
  { code: "level_30", name: "一人前のゲーマー", description: "レベル30に到達した証", icon_name: "workspace_premium" },
  { code: "level_50", name: "熟練の勇者", description: "レベル50に到達した証", icon_name: "diamond" },
  { code: "level_100", name: "ツミクエスト・マスター", description: "レベル100に到達した証", icon_name: "emoji_events" },
  { code: "clear_1", name: "記念すべき第一歩", description: "初めてゲームをクリアした証", icon_name: "sports_esports" },
  { code: "clear_10", name: "十番勝負", description: "ゲームを10本クリアした証", icon_name: "swords" },
  { code: "clear_30", name: "積みゲー崩しの達人", description: "ゲームを30本クリアした証", icon_name: "psychiatry" },
  { code: "clear_50", name: "殿堂入り", description: "ゲームを50本クリアした証", icon_name: "castle" },
  { code: "play_time_100", name: "長き旅路の果て", description: "1つのゲームを100時間以上プレイしてクリアした証", icon_name: "hourglass_empty" },
  { code: "total_play_time_500", name: "時を忘れた冒険者", description: "クリアしたゲームの総プレイ時間が500時間を突破した証", icon_name: "schedule" },
  { code: "genre_rpg_5", name: "ロールプレイヤー", description: "RPGを5本クリアした証", icon_name: "auto_fix_high" },
  { code: "genre_action_5", name: "歴戦の戦士", description: "Actionを5本クリアした証", icon_name: "local_fire_department" }
]

trophies.each do |trophy_data|
  trophy = Trophy.find_or_create_by!(code: trophy_data[:code])
  trophy.assign_attributes(trophy_data.except(:code))
  trophy.save!
end
