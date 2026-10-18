require "test_helper"

class UserTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def setup
    @user = User.new(email: "test@example.com")
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

    user.add_exp!(19_602)

    assert_equal 19_602, user.exp
    assert_equal 100, user.level
  end

  test "Lv99からLv100には累計296EXPが必要" do
    user = User.create!(email: "level-99-test@example.com", level: 99, exp: 19_306)

    user.add_exp!(295)
    assert_equal 99, user.reload.level

    user.add_exp!(1)
    assert_equal 100, user.reload.level
    assert_equal 19_602, user.exp
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
