require "test_helper"
require "minitest/mock"

class GamesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  def setup
    @clerk_user = build_clerk_user("user_clerk_games_test", "test@example.com")
    @user = User.create!(
      email: "test@example.com",
      clerk_user_id: @clerk_user.id,
      name: "テスト勇者"
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
  test "ログインなしで一覧画面にアクセスするとリダイレクトされる" do
    get games_path
    assert_redirected_to root_path
  end

  test "ユーザー名が未設定の場合は名前設定画面へ誘導される" do
    @user.update!(name: nil)

    with_clerk_session do
      get games_path
    end

    assert_redirected_to edit_profile_path
  end

  # ログインしている場合は一覧が表示される
  test "ログイン済みで一覧画面にアクセスできる" do
    with_clerk_session do
      get games_path
    end
    assert_response :success
    assert_select ".level-progress-label:first-child", text: "勇者 テスト勇者"
    assert_select ".level-progress-label:last-child", text: "- Lv. 1"
    assert_select ".level-progress-panel > .profile-edit-link[href='#{edit_profile_path}']"
    assert_select ".level-progress-current .profile-edit-link", count: 0
    assert_select ".level-progress-remaining", text: /次のレベルまであと 100 EXP/
    assert_select '.level-progress-track[role="progressbar"][aria-valuenow="0"]'
  end

  test "一覧画面に現在のレベル内EXPと進捗を表示する" do
    @user.update!(level: 2, exp: 151)

    with_clerk_session do
      get games_path
    end

    assert_response :success
    assert_select ".level-progress-label:last-child", text: "- Lv. 2"
    assert_select ".level-progress-remaining", text: /次のレベルまであと 51 EXP/
    assert_select '.level-progress-track[aria-valuenow="50"]'
    assert_select '.level-progress-fill[style="width: 50%"]'
  end

  test "新規フォームにIGDBサジェスト用の項目が表示される" do
    with_clerk_session do
      get new_game_path
    end

    assert_response :success
    assert_select 'form[data-controller="game-form"]'
    assert_select '[data-game-form-target="suggestions"]'
    assert_select 'input[name="game[igdb_rating]"]'
    assert_select 'input[name="game[developer]"]'
    assert_select 'input[name="game[description]"]'
    assert_select 'input[name="game[play_time_hours]"]'
    assert_select 'input[name="game[play_time_minutes]"]'
    assert_select ".input-unit", text: "時間"
    assert_select ".input-unit", text: "分"
    assert_select ".api-metadata", count: 0
    assert_select 'input[name="game[metascore]"]', count: 0
    assert_select 'input[name="game[average_playtime]"]', count: 0
  end

  test "詳細画面に外部情報とプレイ記録が表示される" do
    @game.update!(
      developer: "開発スタジオ",
      description: "あらすじの1行目\nあらすじの2行目",
      igdb_rating: 91,
      rating: 4,
      purchased_at: Date.new(2026, 1, 2),
      started_at: Date.new(2026, 2, 3),
      finished_at: Date.new(2026, 3, 4),
      memo: "記録の1行目\n記録の2行目"
    )
    @game.update_column(:status, "クリア済")
    @game.update_column(:play_time, 130)

    with_clerk_session do
      get game_path(@game)
    end

    assert_response :success
    assert_select ".game-show-panel"
    assert_select ".game-show-placeholder"
    assert_select ".game-show-title", text: "ゼルダの伝説"
    assert_select ".game-show-developer", text: "開発スタジオ"
    assert_select ".game-show-tag--score", text: /91/
    assert_select ".game-description br"
    assert_select ".game-record-status.is-cleared", text: "クリア済"
    assert_select ".game-total-play-time", text: "2時間10分"
    assert_select ".game-rating .is-active", count: 4
    assert_select ".game-memo br"
    assert_select ".game-show-actions a[href='#{games_path}']"
    assert_select ".game-show-actions a[href='#{edit_game_path(@game)}']"
  end

  # 自分のゲームだけ表示される
  test "自分のゲームだけ表示される" do
    other_user = User.create!(
      email: "other@example.com"
    )
    Game.create!(
      title: "他人のゲーム",
      platform: "PS5",
      genre: "RPG",
      status: "未着手",
      user: other_user
    )

    with_clerk_session do
      get games_path
    end
    assert_response :success
    assert_equal 1, @user.games.count
  end

# 正常にゲームを登録できる
test "ログイン済みでゲームを登録できる" do
  assert_difference("Game.count", 1) do
    with_clerk_session do
      post games_path, params: {
        game: {
          title: "モンスターハンター",
          platform: "Switch",
          genre: "アクション",
          status: "未着手",
          play_time_hours: "2",
          play_time_minutes: "10"
        }
      }
    end
  end
  assert_redirected_to game_path(Game.last)
  assert_equal 130, Game.last.play_time
end

test "ゲーム登録でEXPを獲得した場合にリザルト用データを設定する" do
  with_clerk_session do
    post games_path, params: {
      game: {
        title: "プレイ時間EXPのゲーム",
        status: "未着手",
        play_time_minutes: "5"
      }
    }
  end

  assert_redirected_to game_path(Game.last)
  assert_equal [ { type: :play_time, minutes: 5, exp: 10 } ], assigns(:game).earned_exp_results
  assert_equal 1, assigns(:previous_level)
  assert_equal 0, assigns(:previous_exp)
  assert_equal 1, assigns(:new_level)
  assert_equal 10, assigns(:new_exp)
end

test "EXP獲得時にTurbo Streamでリザルトモーダルを返す" do
  with_clerk_session do
    patch game_path(@game), params: {
      game: { play_time: 2 }
    }, as: :turbo_stream
  end

  assert_response :success
  assert_equal "text/vnd.turbo-stream.html", response.media_type
  assert_includes response.body, 'action="append" targets="body"'
  assert_includes response.body, 'data-controller="exp-result"'
  assert_includes response.body, 'data-exp-result-target="levelText"'
  assert_includes response.body, 'data-exp-result-target="bar"'
  assert_includes response.body, 'data-exp-result-target="levelUpMessage" hidden'
  assert_includes response.body, 'data-action="click->exp-result#close"'
  assert_includes response.body, "プレイ時間"
  assert_includes response.body, "合計獲得EXP"
  assert_includes response.body, "4 EXP"
end

test "IGDBの開発元とあらすじをゲームに保存できる" do
  with_clerk_session do
    post games_path, params: {
      game: {
        title: "メタデータ付きゲーム",
        status: "未着手",
        igdb_rating: 93,
        developer: "開発スタジオ",
        description: "ゲームのあらすじ"
      }
    }
  end

  assert_redirected_to game_path(Game.last)
  assert_equal 93, Game.last.igdb_rating
  assert_equal "開発スタジオ", Game.last.developer
  assert_equal "ゲームのあらすじ", Game.last.description
end

test "ゲーム登録時に英語のあらすじを翻訳して保存する" do
  translated_texts = []
  translator = ->(text) { translated_texts << text; "日本語のあらすじ。" }

  with_clerk_session do
    IgdbApiService.stub(:translate_text, translator) do
      post games_path, params: {
        game: {
          title: "英語概要のゲーム",
          status: "未着手",
          description: "An English summary."
        }
      }
    end
  end

  assert_redirected_to game_path(Game.last)
  assert_equal "日本語のあらすじ。", Game.last.description
  assert_equal [ "An English summary." ], translated_texts
end

test "日本語または空のあらすじは翻訳せずゲームを保存する" do
  translated_texts = []
  translator = ->(text) { translated_texts << text; text }

  with_clerk_session do
    IgdbApiService.stub(:translate_text, translator) do
      post games_path, params: {
        game: {
          title: "日本語概要のゲーム",
          status: "未着手",
          description: "すでに日本語のあらすじです。"
        }
      }
    end

    assert_redirected_to game_path(Game.last)
    assert_equal "すでに日本語のあらすじです。", Game.last.description

    post games_path, params: {
      game: {
        title: "概要なしのゲーム",
        status: "未着手",
        description: ""
      }
    }

    assert_redirected_to game_path(Game.last)
    assert_equal "", Game.last.description
  end
  assert_empty translated_texts
end

test "IGDB検索結果をJSON形式で返す" do
  result = [ { name: "検索ゲーム", image: "https://images.igdb.com/image.jpg", igdb_rating: 93, developer: "開発スタジオ", description: "ゲームのあらすじ", platforms: [ "Switch" ], genres: [ "RPG" ] } ]

  with_clerk_session do
    IgdbApiService.stub(:search, result) do
      get search_games_path, params: { query: "検索ゲーム" }
    end
  end

  assert_response :success
  assert_equal result.as_json, response.parsed_body
  assert_not response.parsed_body.first.key?("metacritic")
end

# タイトルなしでは登録できない
test "タイトルなしでは登録できない" do
  assert_no_difference("Game.count") do
    with_clerk_session do
      post games_path, params: {
        game: {
          title: "",
          platform: "Switch",
          status: "未着手"
        }
      }
    end
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
    assert_redirected_to root_path
  end

  # 自分のゲームを削除できる
  test "自分のゲームを削除できる" do
      assert_difference("Game.count", -1) do
        with_clerk_session do
          delete game_path(@game)
        end
    end
    assert_redirected_to games_path
  end

  # 他人のゲームは削除できない
  test "他人のゲームは削除できない" do
    other_user = User.create!(email: "other@example.com")
    other_game = Game.create!(title: "他人のゲーム", status: "未着手", user: other_user)

    assert_no_difference("Game.count") do
      with_clerk_session do
        delete game_path(other_game)
      end
    end
  end

  # 自分のゲームを更新できる
  test "自分のゲームを更新できる" do
    with_clerk_session do
      patch game_path(@game), params: {
        game: { title: "更新後のタイトル", status: "プレイ中" }
      }
    end
    assert_redirected_to game_path(@game)
    assert_equal "更新後のタイトル", @game.reload.title
  end

  test "ゲーム更新でEXPを獲得した場合にリザルト用データを設定する" do
    with_clerk_session do
      patch game_path(@game), params: {
        game: { play_time_minutes: "5" }
      }
    end

    assert_redirected_to game_path(@game)
    assert_equal [ { type: :play_time, minutes: 5, exp: 10 } ], assigns(:game).earned_exp_results
    assert_equal 1, assigns(:previous_level)
    assert_equal 0, assigns(:previous_exp)
    assert_equal 1, assigns(:new_level)
    assert_equal 10, assigns(:new_exp)
  end


  # 他人のゲームは更新できない
  test "他人のゲームは更新できない" do
    other_user = User.create!(email: "other@example.com")
    other_game = Game.create!(title: "他人のゲーム", status: "未着手", user: other_user)

    with_clerk_session do
      patch game_path(other_game), params: {
        game: { title: "書き換え" }
      }
    end
    assert_redirected_to games_path
    assert_not_equal "書き換え", other_game.reload.title
  end

  test "積みゲー総数とクリア率が正しく計算される" do
    Game.create!(title: "クリア済みゲーム", status: "クリア済", user: @user)
    Game.create!(title: "プレイ中ゲーム", status: "プレイ中", user: @user)

    with_clerk_session do
      get games_path
    end
    assert_response :success
    assert_equal 3, assigns(:total_count)
    assert_equal 33, assigns(:clear_rate)
  end

  test "ステータスで絞り込みができる" do
    Game.create!(title: "プレイ中ゲーム", status: "プレイ中", user: @user)
    Game.create!(title: "クリア済ゲーム", status: "クリア済", user: @user)

    with_clerk_session do
      get games_path, params: { status: "プレイ中" }
    end
    assert_response :success
    assert_equal 1, assigns(:games).count
    assert_equal "プレイ中", assigns(:games).first.status
  end

  private

  def build_clerk_user(id, email)
    email_address_id = "email_#{id}"
    Struct.new(:id, :primary_email_address_id, :email_addresses).new(
      id,
      email_address_id,
      [ Struct.new(:id, :email_address).new(email_address_id, email) ]
    )
  end

  def with_clerk_session
    proxy = Struct.new(:user?, :user).new(true, @clerk_user)
    resolver = Object.new
    resolver.define_singleton_method(:resolve) do |env|
      env["clerk"] = proxy
      [ nil, {}, [] ]
    end

    Clerk::AuthenticateRequest.stub(:new, ->(_context) { resolver }) do
      yield
    end
  end
end
