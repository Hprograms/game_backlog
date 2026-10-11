require "test_helper"

class AccountActivationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password"
    )
  end

  test "有効なトークンでアカウントが有効化される" do
    get edit_account_activation_path(@user.activation_token, email: @user.email)
    @user.reload
    assert @user.activated?
    assert_redirected_to games_path
  end

  test "無効なトークンでは有効化されない" do
    get edit_account_activation_path("invalid_token", email: @user.email)
    @user.reload
    assert_not @user.activated?
    assert_redirected_to root_path
  end

  test "未有効化ユーザーがゲーム一覧にアクセスしてもメールを再送しない" do
    ActionMailer::Base.deliveries.clear
    activation_digest = @user.activation_digest

    sign_in @user
    get games_path

    assert_empty ActionMailer::Base.deliveries
    assert_equal activation_digest, @user.reload.activation_digest
    assert_redirected_to root_path
  end
end