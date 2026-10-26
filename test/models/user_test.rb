require "test_helper"

class UserTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def setup
    @user = User.new(email: "test@example.com")
    %w[level_10 level_30 level_50 level_100].each do |code|
      Trophy.find_or_create_by!(code: code)
    end
  end

  test "ユーザー名が未設定でも有効" do
    [ nil, "" ].each do |name|
      @user.name = name
      assert @user.valid?
    end
  end

  test "ユーザー名は15文字まで" do
    @user.name = "あ" * 15
    assert @user.valid?

    @user.name = "あ" * 16
    assert_not @user.valid?
    assert_includes @user.errors.attribute_names, :name
  end

  test "ClerkユーザーをClerk IDでアプリユーザーに対応づける" do
    clerk_user = clerk_user_record(
      id: "user_clerk_123",
      primary_email_address_id: "email_123",
      email_addresses: [ clerk_email_record(id: "email_123", email_address: "CLERK@example.com") ]
    )

    user = User.find_or_create_for_clerk!(clerk_user)

    assert_equal "user_clerk_123", user.clerk_user_id
    assert_equal "clerk@example.com", user.email
    assert_equal user, User.find_or_create_for_clerk!(clerk_user)
  end

  test "既存のメールアドレスと自動紐付けされる" do
    existing_user = User.create!(email: "existing@example.com")
    clerk_user = clerk_user_record(
      id: "user_clerk_456",
      primary_email_address_id: "email_456",
      email_addresses: [ clerk_email_record(id: "email_456", email_address: existing_user.email) ]
    )

    user = User.find_or_create_for_clerk!(clerk_user)
    assert_equal "user_clerk_456", existing_user.reload.clerk_user_id
    assert_equal user, existing_user
  end

  test "Clerkユーザーに主要メールアドレスがない場合は対応づけない" do
    clerk_user = clerk_user_record(
      id: "user_clerk_789",
      primary_email_address_id: nil,
      email_addresses: []
    )

    assert_raises(ArgumentError) do
      User.find_or_create_for_clerk!(clerk_user)
    end
  end

  test "総EXPに基づいて複数レベルを上げる" do
    user = User.create!(email: "level-test@example.com")
    game = user.games.create!(title: "Level-up trigger game", status: "未着手")

    user.add_exp!(155_430, game)

    assert_equal 155_430, user.exp
    assert_equal 100, user.level
    assert user.user_trophies.joins(:trophy).exists?(trophies: { code: "level_100" })
    assert Activity.exists?(user: user, game: game, action_type: "level_up")
  end

  test "Lv99からLv100には3040EXPが必要" do
    user = User.create!(email: "level-99-test@example.com", level: 99, exp: 152_390)
    game = user.games.create!(title: "Level 100 trigger game", status: "未着手")

    user.add_exp!(3_039, game)
    assert_equal 99, user.reload.level

    user.add_exp!(1, game)
    assert_equal 100, user.reload.level
    assert_equal 155_430, user.exp
    assert_equal 1, Activity.where(user: user, game: game, action_type: "level_up").count
  end

  test "Lv100以降は次のレベルまで3000EXPで、累計必要EXPにも反映する" do
    user = User.new(level: 100)

    assert_equal 3_000, user.exp_required_for_next_level
    assert_equal 158_430, user.total_exp_required_for_level(101)
  end

  test "条件を満たした全トロフィーを獲得し、トロフィー獲得判定メソッドを再実行しても獲得トロフィー重複しない" do
    user = User.create!(email: "trophy-test@example.com", level: 100)
    trophy_codes = %w[
      level_10 level_30 level_50 level_100
      clear_1 clear_10 clear_30 clear_50
      play_time_100 total_play_time_500
      genre_rpg_5 genre_action_5
    ]
    trophy_codes.each do |code|
      Trophy.find_or_create_by!(code: code) do |trophy|
        trophy.assign_attributes(name: code, description: code, icon_name: code)
      end
    end

    50.times do |index|
      user.games.create!(
        title: "Game #{index}",
        genre: index < 5 ? "RPG" : (index < 10 ? "アクション" : "その他"),
        status: "未着手",
        play_time: index.zero? ? 100 : 10
      )
    end
    user.games.update_all(status: "クリア済")

    trigger_game = user.games.first
    user.unlock_trophies!(trigger_game)
    assert_equal 12, user.user_trophies.count
    assert user.user_trophies.all? { |user_trophy| user_trophy.unlocked_at.present? }
    assert_equal 12, Activity.where(user: user, game: trigger_game, action_type: "trophy_unlocked").count

    user.unlock_trophies!(trigger_game)
    assert_equal 12, user.user_trophies.count
    assert_equal 12, Activity.where(user: user, game: trigger_game, action_type: "trophy_unlocked").count
  end

  test "クリアしていないゲームはクリア数とプレイ時間・ジャンル判定に含めない" do
    user = User.create!(email: "uncleared-trophy-test@example.com", level: 1)
    %w[clear_1 play_time_100 total_play_time_500 genre_rpg_5].each do |code|
      Trophy.create!(code: code, name: code, description: code, icon_name: code)
    end
    game = user.games.create!(title: "Uncleared RPG", genre: "RPG", status: "プレイ中")
    game.update_column(:play_time, 500)

    user.unlock_trophies!(game)

    assert_empty user.user_trophies
  end

  private

  def clerk_user_record(id:, primary_email_address_id:, email_addresses:)
    Struct.new(:id, :primary_email_address_id, :email_addresses).new(
      id,
      primary_email_address_id,
      email_addresses
    )
  end

  def clerk_email_record(id:, email_address:)
    Struct.new(:id, :email_address).new(id, email_address)
  end
end
