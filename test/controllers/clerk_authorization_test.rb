require "test_helper"

class ClerkAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @clerk_user = create_clerk_user("user_clerk_owner", "owner@example.com")
    @user = User.create!(
      email: "owner@example.com",
      clerk_user_id: @clerk_user.id,
      name: "オーナー"
    )
    @game = Game.create!(title: "Owner game", status: "未着手", user: @user)
  end

  test "未認証のHTMLリクエストはホーム画面へ誘導する" do
    get games_path

    assert_redirected_to root_path
  end

  test "未認証のJSONリクエストは401を返す" do
    get search_games_path, params: { query: "game" }, as: :json

    assert_response :unauthorized
  end

  test "Clerkセッションがあればアプリ内ユーザーのゲーム一覧を表示する" do
    with_clerk_session(@clerk_user) do
      get games_path
    end

    assert_response :success
    assert_select ".game-poster-card", text: /Owner game/
  end

  test "別のClerkユーザーは他人のゲームを参照・更新できない" do
    attacker = create_clerk_user("user_clerk_attacker", "attacker@example.com")
    User.create!(
      email: "attacker@example.com",
      clerk_user_id: attacker.id,
      name: "侵入者"
    )

    with_clerk_session(attacker) do
      get game_path(@game)
    end

    assert_redirected_to games_path

    with_clerk_session(attacker) do
      patch game_path(@game), params: { game: { title: "Changed by attacker" } }
    end

    assert_redirected_to games_path
    assert_equal "Owner game", @game.reload.title
  end

  test "ゲーム作成時の所有者はClerkセッションのアプリ内ユーザーになる" do
    assert_difference("Game.count", 1) do
      with_clerk_session(@clerk_user) do
        post games_path, params: { game: { title: "New owner game", status: "未着手" } }
      end
    end

    assert_equal @user, Game.find_by!(title: "New owner game").user
  end

  private

  def create_clerk_user(id, email)
    email_address_id = "email_#{id}"
    Struct.new(:id, :primary_email_address_id, :email_addresses).new(
      id,
      email_address_id,
      [ Struct.new(:id, :email_address).new(email_address_id, email) ]
    )
  end

  def with_clerk_session(clerk_user)
    proxy = Struct.new(:user?, :user).new(true, clerk_user)
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
