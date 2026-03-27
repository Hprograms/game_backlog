require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password",
      activated: true,
      activated_at: Time.zone.now
    )
    @game = Game.create!(
      title: "ゼルダの伝説",
      platform: "Switch",
      genre: "アクション",
      status: "未着手",
      user: @user
    )
  end

  # ログインしていない場合はリダイレクトされる
  test "ログインなしでindexにアクセスするとリダイレクトされる" do
    get games_path
    assert_redirected_to new_user_session_path
  end

  # ログインしている場合は一覧が表示される
  test "ログイン済みでindexにアクセスできる" do
    sign_in @user
    get games_path
    assert_response :success
  end

  # 自分のゲームだけ表示される
  test "自分のゲームだけ表示される" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password"
    )
    Game.create!(
      title: "他人のゲーム",
      platform: "PS5",
      genre: "RPG",
      status: "未着手",
      user: other_user
    )

    sign_in @user
    get games_path
    assert_response :success
    assert_equal 1, @user.games.count
  end

  # 正常にゲームを登録できる
test "ログイン済みでゲームを登録できる" do
  sign_in @user
  assert_difference("Game.count", 1) do
    post games_path, params: {
      game: {
        title: "モンスターハンター",
        platform: "Switch",
        genre: "アクション",
        status: "未着手"
      }
    }
  end
  assert_redirected_to game_path(Game.last)
end

# タイトルなしでは登録できない
test "タイトルなしでは登録できない" do
  sign_in @user
  assert_no_difference("Game.count") do
    post games_path, params: {
      game: {
        title: "",
        platform: "Switch",
        status: "未着手"
      }
    }
  end
  assert_response :unprocessable_entity
end

  # ログインなしでは登録できない
  test "ログインなしでは登録できない" do
    assert_no_difference("Game.count") do
      post games_path, params: {
        game: {
          title: "モンスターハンター",
          status: "未着手"
        }
      }
    end
    assert_redirected_to new_user_session_path
  end

    # 自分のゲームを削除できる
  test "自分のゲームを削除できる" do
    sign_in @user
    assert_difference("Game.count", -1) do
      delete game_path(@game)
    end
    assert_redirected_to games_path
  end

  # 他人のゲームは削除できない
  test "他人のゲームは削除できない" do
    other_user = User.create!(email: "other@example.com", password: "password")
    other_game = Game.create!(title: "他人のゲーム", status: "未着手", user: other_user)

    sign_in @user
    assert_no_difference("Game.count") do
      delete game_path(other_game)
    end
  end

  # 自分のゲームを更新できる
  test "自分のゲームを更新できる" do
    sign_in @user
    patch game_path(@game), params: {
      game: { title: "更新後のタイトル", status: "プレイ中" }
    }
    assert_redirected_to game_path(@game)
    assert_equal "更新後のタイトル", @game.reload.title
  end

 
  # 他人のゲームは更新できない
  test "他人のゲームは更新できない" do
    other_user = User.create!(email: "other@example.com", password: "password")
    other_game = Game.create!(title: "他人のゲーム", status: "未着手", user: other_user)

    sign_in @user
    patch game_path(other_game), params: {
      game: { title: "書き換え" }
    }
    assert_redirected_to games_path
    assert_not_equal "書き換え", other_game.reload.title
  end

  test "積みゲー総数とクリア率が正しく計算される" do
    sign_in @user
    Game.create!(title: "クリア済みゲーム", status: "クリア済", user: @user)
    Game.create!(title: "プレイ中ゲーム", status: "プレイ中", user: @user)

    get games_path
    assert_response :success
    assert_equal 3, assigns(:total_count)
    assert_equal 33, assigns(:clear_rate)
  end
end 