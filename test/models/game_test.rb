require "test_helper"

class GameTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @user = User.create!(email: "game-test@example.com")
    @game = @user.games.create!(title: "Test Game", status: "プレイ中", play_time: 30)
  end

  test "clear awards base and play time EXP and updates level" do
    @game.update!(status: "クリア済")

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
    assert @game.reload.exp_awarded_for_clear
  end

  test "clear awards base EXP when play time is nil" do
    @game.update!(play_time: nil, status: "クリア済")

    assert_equal 100, @user.reload.exp
    assert_equal 2, @user.level
  end

  test "entering play time after a clear with no play time awards only the missing bonus once" do
    @game.update!(play_time: nil, status: "クリア済")
    @game.update!(play_time: 30)
    @game.update!(play_time: 40)

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
    assert @game.reload.play_time_exp_awarded_for_clear
  end

  test "changing play time after its clear bonus was awarded gives no more EXP" do
    @game.update!(status: "クリア済")
    @game.update!(play_time: 40)

    assert_equal 400, @user.reload.exp
    assert @game.reload.play_time_exp_awarded_for_clear
  end

  test "clear does not award EXP more than once" do
    @game.update!(status: "クリア済")
    @game.update!(status: "プレイ中")
    @game.update!(status: "クリア済")

    assert_equal 400, @user.reload.exp
    assert_equal 4, @user.level
  end

  test "clear does not award EXP if the game was already credited" do
    @game.update!(exp_awarded_for_clear: true, status: "クリア済")

    assert_equal 0, @user.reload.exp
    assert_equal 1, @user.level
  end
end
