require "test_helper"

class GameTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @user = User.create!(email: "game-test@example.com")
    Trophy.find_or_create_by!(code: "clear_1")
    Trophy.find_or_create_by!(code: "level_10")
    @game = @user.games.create!(title: "Test Game", status: "プレイ中", play_time: 30)
  end

  test "クリアで5000EXPとプレイ時間EXPが付与されレベルが更新される" do
    @game.update!(status: "クリア済")

    assert_equal 8_000, @user.reload.exp
    assert_equal 21, @user.level
    assert @game.reload.exp_awarded_for_clear
    assert @user.user_trophies.joins(:trophy).exists?(trophies: { code: "clear_1" })
    assert Activity.exists?(user: @user, game: @game, action_type: "level_up")
    assert Activity.exists?(user: @user, game: @game, action_type: "trophy_unlocked")
  end

  test "クリア済ゲームのプレイ時間更新でトロフィーを判定する" do
    Trophy.find_or_create_by!(code: "play_time_100")

    @game.update!(status: "クリア済")
    @game.update!(play_time: 100)

    assert @user.user_trophies.joins(:trophy).exists?(trophies: { code: "play_time_100" })
  end

  test "クリア済みステータスでもプレイ時間の更新でEXPが付与される" do
    @game.update!(play_time: nil, status: "クリア済")
    assert_equal 8_000, @user.reload.exp

    @game.update!(play_time: 40)

    assert_equal 9_000, @user.reload.exp
    assert_equal 40, @game.reload.awarded_play_time
  end

  test "プレイ時間をnilにしても既に付与されたEXPは維持される" do
    @game.update!(play_time: nil, status: "クリア済")

    assert_equal 8_000, @user.reload.exp
    assert_equal 21, @user.level
  end

  test "クリア後もプレイ時間の増加に応じてEXPが付与される" do
    @game.update!(play_time: nil, status: "クリア済")
    @game.update!(play_time: 30)
    @game.update!(play_time: 40)

    assert_equal 9_000, @user.reload.exp
    assert_equal 22, @user.level
    assert_equal 40, @game.reload.awarded_play_time
  end

  test "クリア報酬はプレイ時間EXPと独立して付与される" do
    @game.update!(status: "クリア済")
    @game.update!(play_time: 40)

    assert_equal 9_000, @user.reload.exp
    assert_equal 22, @user.level
    assert_equal 40, @game.reload.awarded_play_time
  end

  test "プレイ時間の増分だけEXPが付与され、減少ではEXPが減らない" do
    @game.update!(play_time: 35)
    assert_equal 3_500, @user.reload.exp
    assert_equal 35, @game.reload.awarded_play_time

    @game.update!(play_time: 30)
    assert_equal 3_500, @user.reload.exp
    assert_equal 35, @game.reload.awarded_play_time
  end

  test "クリア報酬は複数回付与されない" do
    @game.update!(status: "クリア済")
    @game.update!(status: "プレイ中")
    @game.update!(status: "クリア済")

    assert_equal 8_000, @user.reload.exp
    assert_equal 21, @user.level
  end

  test "プレイ中でゲームを作成するとstartedアクティビティを作成する" do
    activity = Activity.find_by!(game: @game, action_type: "started")

    assert_equal @user.id, activity.user_id
    assert_not_nil activity.occurred_at
  end

  test "プレイ中への切り替えを繰り返してもstartedアクティビティは一度だけ作成する" do
    game = @user.games.create!(title: "Unstarted Game", status: "未着手")
    game.update!(status: "プレイ中")
    game.update!(status: "未着手")
    game.update!(status: "プレイ中")

    activities = Activity.where(game: game, action_type: "started")
    assert_equal 1, activities.count
    assert_equal @user.id, activities.sole.user_id
    assert_not_nil activities.sole.occurred_at
  end

  test "クリアへの変更でclearedアクティビティを一度だけ作成する" do
    @game.update!(status: "クリア済")
    @game.update!(status: "プレイ中")
    @game.update!(status: "クリア済")

    activities = Activity.where(game: @game, action_type: "cleared")
    assert_equal 1, activities.count
    assert_equal @user.id, activities.sole.user_id
    assert_not_nil activities.sole.occurred_at
  end

  test "クリア済ゲームの評価またはメモを更新するとreviewedを作成して時刻を更新する" do
    @game.update!(status: "クリア済", rating: 5)
    activity = Activity.find_by!(game: @game, action_type: "reviewed")
    original_occurred_at = activity.occurred_at

    travel 2.seconds do
      @game.update!(memo: "クリア後の感想")
    end

    activity.reload
    assert_operator activity.occurred_at, :>, original_occurred_at
    assert_equal 1, Activity.where(game: @game, action_type: "reviewed").count
    assert_equal @user.id, activity.user_id
  end

  test "クリアとレビューが同じ保存で条件を満たした場合は両方作成する" do
    game = @user.games.create!(
      title: "Cleared Game",
      status: "クリア済",
      rating: 4,
      memo: "Reviewed while clearing"
    )

    assert Activity.exists?(game: game, action_type: "cleared")
    assert Activity.exists?(game: game, action_type: "reviewed")
    assert_not Activity.exists?(game: game, action_type: "started")
  end

  test "すでに報酬済みのゲームにはクリアEXPは付与されない" do
    @game.update!(exp_awarded_for_clear: true, status: "クリア済")

    assert_equal 3_000, @user.reload.exp
    assert_equal 12, @user.level
  end
end
