require "test_helper"

class GameTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @user = User.create!(email: "game-test@example.com")
    @game = @user.games.create!(title: "Test Game", status: "プレイ中", play_time: 30)
  end

  test "クリアで基本EXPとプレイ時間EXPが付与されレベルが更新される" do
    @game.update!(status: "クリア済")

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
    assert @game.reload.exp_awarded_for_clear
  end

  test "プレイ時間がnilのときに基本EXPだけが付与される" do
    @game.update!(play_time: nil, status: "クリア済")

    assert_equal 100, @user.reload.exp
    assert_equal 2, @user.level
  end

  test "クリア後にプレイ時間を追加しても不足分のボーナスは1回だけ付与される" do
    @game.update!(play_time: nil, status: "クリア済")
    @game.update!(play_time: 30)
    @game.update!(play_time: 40)

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
    assert @game.reload.play_time_exp_awarded_for_clear
  end

  test "クリア報酬を付与した後にプレイ時間を変更しても追加EXPは発生しない" do
    @game.update!(status: "クリア済")
    @game.update!(play_time: 40)

    assert_equal 400, @user.reload.exp
    assert @game.reload.play_time_exp_awarded_for_clear
  end

  test "クリア報酬は複数回付与されない" do
    @game.update!(status: "クリア済")
    @game.update!(status: "プレイ中")
    @game.update!(status: "クリア済")

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
  end

  test "すでに報酬済みのゲームにはクリアEXPは付与されない" do
    @game.update!(exp_awarded_for_clear: true, status: "クリア済")

    assert_equal 0, @user.reload.exp
    assert_equal 1, @user.level
  end
end
