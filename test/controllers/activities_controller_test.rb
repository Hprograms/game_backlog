require "test_helper"
require "minitest/mock"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @clerk_user = clerk_user_record("user_clerk_activities_test", "activities@example.com")
    @user = User.create!(
      email: "activities@example.com",
      clerk_user_id: @clerk_user.id,
      name: "テスト勇者"
    )
    @game = Game.create!(user: @user, title: "冒険のゲーム", status: "未着手")
    21.times do |index|
      Activity.create!(
        user: @user,
        game: @game,
        action_type: "started",
        occurred_at: index.minutes.ago
      )
    end
  end

  test "冒険の書は新しい順に20件表示し、次ページへのリンクを表示する" do
    with_clerk_session do
      get activities_path
    end

    assert_response :success
    assert_select "h1.activities-title", text: "冒険の書"
    assert_select "#activities .activity-message", count: 20
    assert_select "#activities .activity-message-text", text: /勇者 テスト勇者 は 『冒険のゲーム』 の ぼうけんを はじめた！/
    assert_select "#activities .activity-message--blue .activity-message-icon", text: "sports_esports", count: 20
    assert_select "#load-more-container a[href='#{activities_path(page: 2)}']"
    first_datetime = Time.iso8601(css_select("#activities time").first["datetime"])
    last_datetime = Time.iso8601(css_select("#activities time").last["datetime"])
    assert_operator first_datetime, :>, last_datetime
  end

  test "アクションごとにテーマ色とアイコンを表示する" do
    expected_themes = {
      "cleared" => [ "yellow", "emoji_events", "を クリアした！" ],
      "reviewed" => [ "green", "rate_review", "の レビューを かいた！" ],
      "level_up" => [ "purple", "trending_up", "レベルが あがった！" ],
      "trophy_unlocked" => [ "orange", "military_tech", "トロフィーを てにいれた！" ]
    }
    expected_themes.each_key do |action_type|
      Activity.create!(user: @user, game: @game, action_type: action_type, occurred_at: Time.current)
    end

    with_clerk_session do
      get activities_path
    end

    assert_response :success
    expected_themes.each do |action_type, (color, icon, message)|
      assert_select ".activity-message--#{color} .activity-message-icon", text: icon
      assert_select ".activity-message--#{color} .activity-message-text", text: /#{Regexp.escape(message)}/
    end
  end

  test "追加読み込みでは残りの履歴を追加し、次がなければボタンを空にする" do
    with_clerk_session do
      get activities_path(page: 2), headers: { "Accept" => Mime[:turbo_stream].to_s }
    end

    assert_response :success
    assert_select 'turbo-stream[action="append"][target="activities"] template .activity-message', count: 1
    assert_select 'turbo-stream[action="replace"][target="load-more-container"]' do
      assert_select "#load-more-container"
      assert_select "a", count: 0
    end
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
