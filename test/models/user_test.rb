require "test_helper"

class UserTest < ActiveSupport::TestCase
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

  test "Clerkユーザーにprimary emailがない場合は対応づけない" do
    clerk_user = clerk_user_record(
      id: "user_clerk_789",
      primary_email_address_id: nil,
      email_addresses: []
    )

    assert_raises(ArgumentError) do
      User.find_or_create_for_clerk!(clerk_user)
    end
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
