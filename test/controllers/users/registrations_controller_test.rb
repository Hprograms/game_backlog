require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "新規登録時に有効化メールを1通だけ送信する" do
    ActionMailer::Base.deliveries.clear

    post user_registration_path, params: {
      user: {
        email: "new-user@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    assert_response :redirect
    assert_equal 1, ActionMailer::Base.deliveries.count

    follow_redirect!

    assert_equal 1, ActionMailer::Base.deliveries.count
  end
end
