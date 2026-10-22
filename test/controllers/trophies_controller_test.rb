require "test_helper"
require "minitest/mock"

class TrophiesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @clerk_user = clerk_user_record("user_clerk_trophies_test", "trophies@example.com")
    @user = User.create!(
      email: "trophies@example.com",
      clerk_user_id: @clerk_user.id,
      name: "トロフィー勇者"
    )
    @unlocked_trophy = Trophy.create!(
      code: "level_10",
      name: "冒険の始まり",
      description: "レベル10に到達した証",
      icon_name: "military_tech"
    )
    @locked_trophy = Trophy.create!(
      code: "clear_1",
      name: "記念すべき第一歩",
      description: "初めてゲームをクリアした証",
      icon_name: "sports_esports"
    )
    @play_time_trophy = Trophy.create!(
      code: "play_time_100",
      name: "精神と時の部屋",
      description: "100時間以上プレイした証",
      icon_name: "hourglass_empty"
    )
    @total_play_time_trophy = Trophy.create!(
      code: "total_play_time_500",
      name: "時間泥棒の被害者",
      description: "総プレイ時間500時間の証",
      icon_name: "schedule"
    )
    @genre_trophy = Trophy.create!(
      code: "genre_rpg_5",
      name: "ロールプレイヤー",
      description: "RPGを5本クリアした証",
      icon_name: "auto_fix_high"
    )
    @user.user_trophies.create!(trophy: @unlocked_trophy, unlocked_at: Time.zone.local(2026, 10, 18))
    @user.user_trophies.create!(trophy: @total_play_time_trophy, unlocked_at: Time.zone.local(2026, 10, 19))
  end

  test "ログインなしで一覧画面にアクセスするとリダイレクトされる" do
    get trophies_path

    assert_redirected_to new_user_session_path
  end

  test "獲得済みと未獲得のトロフィーをカテゴリ別に表示する" do
    with_clerk_session do
      get trophies_path
    end

    assert_response :success
    assert_select ".trophy-category-heading h2", text: "レベル到達"
    assert_select ".trophy-category-heading h2", text: "ゲームクリア数"
    assert_select ".trophy-category-heading h2", text: "プレイ時間"
    assert_select ".trophy-category-heading h2", text: "ジャンルマスター"
    assert_select ".trophy-card.is-unlocked .trophy-card-name", text: "冒険の始まり"
    assert_select ".trophy-card.is-locked .trophy-card-name", text: "記念すべき第一歩"
    assert_select ".trophy-card.is-unlocked .trophy-card-name", text: "時間泥棒の被害者"
    assert_select ".trophy-card.is-locked .trophy-card-name", text: "精神と時の部屋"
    assert_select ".trophy-card.is-locked .trophy-card-name", text: "ロールプレイヤー"
    assert_select ".trophy-card-date", text: "2026.10.18 獲得"
    assert_select ".trophy-card-icon", text: "military_tech"
  end

  test "ヘッダーからトロフィー一覧へ移動できる" do
    with_clerk_session do
      get trophies_path
    end

    assert_select "a[href='#{trophies_path}']", text: /トロフィー/
  end

  private

  def clerk_user_record(id, email)
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
