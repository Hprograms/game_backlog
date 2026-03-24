require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = User.new(email: "test@example.com", password: "password")
    @user.create_activation_digest
  end

  test "有効化メールが送信される" do
    mail = UserMailer.activation_email(@user)
    assert_equal "アカウントを有効化してください", mail.subject
    assert_equal [@user.email], mail.to
    assert_equal ["noreply@gamebacklog.com"], mail.from
    assert_match @user.activation_token, mail.body.parts.first.decoded
  end

  test "パスワードリセットメールが送信される" do
    @user.save
    token = @user.send_reset_password_instructions
    mail = ActionMailer::Base.deliveries.last
    assert_equal "パスワードのリセット手順", mail.subject
    assert_equal [@user.email], mail.to
    assert_match token, mail.body.encoded
  end
end