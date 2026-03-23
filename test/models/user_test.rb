require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(email: "test@example.com", password: "password")
  end

  test "有効化トークンとダイジェストが生成される" do
    @user.create_activation_digest
    assert_not_nil @user.activation_token
    assert_not_nil @user.activation_digest
  end

  test "トークンの認証ができる" do
    @user.create_activation_digest
    assert @user.authenticated?(@user.activation_token)
  end

  test "新規登録時にactivatedがfalseになる" do
    @user.save
    assert_not @user.activated
  end
end