require "test_helper"

class UserTrophyConditionsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  TROPHY_CODES = %w[
    level_10 level_30 level_50 level_100
    clear_1 clear_10 clear_30 clear_50
    play_time_100 total_play_time_500
    genre_rpg_5 genre_action_5
  ].freeze

  setup do
    @user = User.create!(email: "trophy-conditions-#{SecureRandom.hex(6)}@example.com")
    TROPHY_CODES.each do |code|
      Trophy.find_or_create_by!(code: code) do |trophy|
        trophy.assign_attributes(name: code, description: code, icon_name: code)
      end
    end
  end

  test "レベル到達トロフィーは各レベルの境界で獲得する" do
    {
      9 => [],
      10 => %w[level_10],
      29 => %w[level_10],
      30 => %w[level_10 level_30],
      49 => %w[level_10 level_30],
      50 => %w[level_10 level_30 level_50],
      99 => %w[level_10 level_30 level_50],
      100 => %w[level_10 level_30 level_50 level_100]
    }.each do |level, expected_codes|
      user = build_user(level: level)

      assert_equal expected_codes.sort, unlocked_codes(user), "level #{level}"
    end
  end

  test "クリア数トロフィーはクリア本数の境界で獲得する" do
    {
      0 => [],
      1 => %w[clear_1],
      9 => %w[clear_1],
      10 => %w[clear_1 clear_10],
      29 => %w[clear_1 clear_10],
      30 => %w[clear_1 clear_10 clear_30],
      49 => %w[clear_1 clear_10 clear_30],
      50 => %w[clear_1 clear_10 clear_30 clear_50]
    }.each do |count, expected_codes|
      user = build_user
      add_cleared_games(user, count)

      assert_equal expected_codes.sort, unlocked_codes(user), "cleared games #{count}"
    end
  end

  test "100時間トロフィーは個別クリア済みゲームが6000分以上のときだけ獲得する" do
    {
      5_999 => %w[clear_1],
      6_000 => %w[clear_1 play_time_100]
    }.each do |play_time, expected_codes|
      user = build_user
      add_cleared_games(user, 1, play_time: play_time)

      assert_equal expected_codes.sort, unlocked_codes(user), "play time #{play_time} minutes"
    end
  end

  test "総プレイ時間500時間トロフィーはクリア済みゲームの合計が30000分以上のときだけ獲得する" do
    {
      29_999 => %w[clear_1],
      30_000 => %w[clear_1 total_play_time_500]
    }.each do |total_play_time, expected_codes|
      user = build_user
      play_times = Array.new(5, 5_000) + [ total_play_time - 25_000 ]
      add_cleared_games(user, play_times.size, play_times: play_times)

      assert_equal expected_codes.sort, unlocked_codes(user), "total play time #{total_play_time} minutes"
    end
  end

  test "ジャンルトロフィーは該当ジャンルのクリアが5本に達したときだけ獲得する" do
    {
      "RPG" => "genre_rpg_5",
      "アクション" => "genre_action_5"
    }.each do |genre, trophy_code|
      [ 4, 5 ].each do |count|
        user = build_user
        add_cleared_games(user, count, genre: genre)
        expected_codes = count == 5 ? %w[clear_1] + [ trophy_code ] : %w[clear_1]

        assert_equal expected_codes.sort, unlocked_codes(user), "#{genre} cleared games #{count}"
      end
    end
  end

  test "未クリアのプレイ時間は個別・合計時間の条件に含めない" do
    user = build_user
    add_cleared_games(user, 0)
    user.games.create!(title: "Uncleared long game", status: "未着手", play_time: 30_000)

    assert_empty unlocked_codes(user)
  end

  private

  def build_user(level: 1)
    User.create!(email: "trophy-conditions-#{SecureRandom.hex(6)}@example.com", level: level)
  end

  def add_cleared_games(user, count, play_time: 0, play_times: nil, genre: "その他")
    count.times do |index|
      user.games.create!(
        title: "#{genre} game #{index}",
        status: "未着手",
        genre: genre
      )
    end
    if play_times
      user.games.order(:id).each_with_index do |game, index|
        game.update_columns(status: "クリア済", play_time: play_times[index])
      end
    else
      user.games.update_all(status: "クリア済", play_time: play_time)
    end
  end

  def unlocked_codes(user)
    user.unlock_trophies!.map(&:code).sort
  end
end
