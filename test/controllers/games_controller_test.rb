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

    Trophy.create!(code: "clear_1", name: "初クリア", description: "初めてゲームをクリアした")
    Trophy.create!(code: "level_10", name: "レベル10", description: "レベル10に到達した")
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
    assert_select ".header-level-container"
    assert_select "span.text-white.fw-bold", text: "Lv.1"
    assert_select ".header-progress-track"
    assert_select ".header-level-container[title='0 / 100 EXP']"
  end

  test "一覧画面にタイマーUIとPLAYボタンを表示する" do
    with_clerk_session do
      get games_path
    end

    assert_response :success
    assert_select "html[data-controller='timer']"
    assert_select "#floating-timer[data-timer-target='floating'][hidden]"
    assert_select ".timer-warning[data-timer-target='warning'][hidden]"
    assert_select ".timer-modal-overlay[data-timer-target='overlay'][hidden]"
    assert_select ".timer-modal-poster[data-timer-target='poster'][hidden]"
    assert_select ".timer-modal-title[data-timer-target='modalTitle']"
    assert_select ".timer-modal-time-display[data-timer-target='modalTime']"
    assert_select "#timer-clear-check[data-timer-target='clearCheck'][data-action='change->timer#toggleClearWarning']"
    assert_select '[data-timer-target="clearWarning"][hidden]'
    assert_select "img.cracker-icon[src*='cracker']"
    assert_select "button[data-timer-target='saveButton'][data-action='click->timer#save']", text: "EXPを獲得して終了"
    assert_select "button[data-action='click->timer#resume']", text: /計測を再開する/
    assert_select "button.btn-play[data-action='click->timer#start'][data-game-id='#{@game.id}'][data-game-title='#{@game.title}']"
  end

  test "一覧画面に現在のレベル内EXPと進捗を表示する" do
    @user.update!(level: 2, exp: 151)

    with_clerk_session do
      get games_path
    end

    assert_response :success
    assert_select "span.text-white.fw-bold", text: "Lv.2"
    assert_select ".header-level-container[title='51 / 130 EXP']"
    assert_select '.header-progress-fill[style="width: 39%"]'
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

test "EXP獲得時に詳細画面で日本語リザルトモーダルを表示する" do
  with_clerk_session do
    patch game_path(@game), params: {
      game: { play_time: 2 }
    }, as: :turbo_stream
    assert_redirected_to game_path(@game)
    follow_redirect!
  end

  assert_response :success
  assert_includes response.body, 'data-controller="exp-result"'
  assert_includes response.body, 'data-exp-result-target="levelText"'
  assert_includes response.body, 'data-exp-result-target="bar"'
  assert_includes response.body, 'data-exp-result-target="levelUpLogo" hidden'
  assert_select "button.exp-result-close[data-exp-result-target='closeButton'][hidden]"
  assert_includes response.body, "cracker-left"
  assert_includes response.body, "cracker-right"
  assert_includes response.body, "exp_results/levelup"
  assert_includes response.body, "exp-result-levelup-logo-wrapper"
  assert_includes response.body, 'data-action="click->exp-result#close"'
  assert_includes response.body, "プレイ時間ボーナス"
  assert_includes response.body, "計："
  assert_includes response.body, "冒 険 の 成 果"
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

  test "タイマーのプレイ時間を加算してEXPリザルトを返す" do
    with_clerk_session do
      post timer_update_game_path(@game),
        params: { play_time_minutes: 25 },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 25, @game.reload.play_time
    assert_equal "プレイ中", @game.status
    assert_equal 60, @user.reload.exp
    assert_includes response.body, 'action="append" targets="body"'
    assert_includes response.body, "タイマーボーナス"
    assert_includes response.body, "+ 10 EXP"
    assert_includes response.body, "計："
    response_fragment = Nokogiri::HTML.fragment(response.body)
    stats_template = response_fragment.at_css('turbo-stream[target="game-stats"] template')
    list_template = response_fragment.at_css('turbo-stream[target="games-list"] template')
    assert_equal %w[1 0 1 0], stats_template.css(".stat-value").map { |value| value.text.strip }
    assert_includes list_template.text, "プレイ中"
  end

  test "EXPを獲得しないタイマー記録でも0 EXPの内訳を表示する" do
    with_clerk_session do
      post timer_update_game_path(@game),
        params: { play_time_minutes: 0 },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_includes response.body, "プレイ時間ボーナス (0分)"
    assert_includes response.body, "+ 0 EXP"
    assert_includes response.body, "計："
  end

  test "1分のタイマー計測でも最低1EXPのボーナスが付与される" do
    with_clerk_session do
      post timer_update_game_path(@game),
        params: { play_time_minutes: 1 },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "プレイ中", @game.reload.status
    assert_equal 3, @user.reload.exp
    assert_includes response.body, "プレイ時間ボーナス (1分)"
    assert_includes response.body, "+ 1 EXP"
  end

  test "タイマーのクリア結果でプレイ時間とクリア状態を保存してEXPを付与する" do
    with_clerk_session do
      post timer_update_game_path(@game),
        params: { play_time_minutes: 10, status: "cleared" },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success, response.body
    assert_equal 10, @game.reload.play_time
    assert_equal "クリア済", @game.status
    assert_equal 5_024, @user.reload.exp
    assert_includes response.body, "クリアボーナス"
    assert_includes response.body, "タイマーボーナス"
    assert_includes response.body, "計："
  end

  test "タイマー結果でゲーム一覧と件数を更新し、絞り込みから外れたカードを除く" do
    other_game = @user.games.create!(title: "別の未着手ゲーム", status: "未着手")

    with_clerk_session do
      post timer_update_game_path(@game, filter_status: "未着手"),
        params: { play_time_minutes: 10, status: "cleared" },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "クリア済", @game.reload.status

    response_fragment = Nokogiri::HTML.fragment(response.body)
    stats_template = response_fragment.at_css('turbo-stream[target="game-stats"] template')
    list_template = response_fragment.at_css('turbo-stream[target="games-list"] template')
    assert stats_template
    assert list_template
    assert_equal %w[2 1 0 1], stats_template.css(".stat-value").map { |value| value.text.strip }
    assert_includes stats_template.text, "クリア済 (50%)"
    assert_includes list_template.text, other_game.title
    refute_includes list_template.to_html, "poster_game_#{@game.id}"
  end

  test "不正なタイマー結果は保存しない" do
    with_clerk_session do
      post timer_update_game_path(@game),
        params: { play_time_minutes: -1 },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_response :unprocessable_entity

      post timer_update_game_path(@game),
        params: { play_time_minutes: "invalid" },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
    assert_nil @game.reload.play_time
    assert_equal "未着手", @game.status
    assert_equal 0, @user.reload.exp
  end

  test "他人のゲームのタイマー結果は保存できない" do
    other_user = User.create!(email: "timer-other@example.com")
    other_game = Game.create!(title: "他人のゲーム", status: "未着手", user: other_user)

    with_clerk_session do
      post timer_update_game_path(other_game),
        params: { play_time_minutes: 10 },
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :not_found
    assert_nil other_game.reload.play_time
    assert_equal "未着手", other_game.status
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
