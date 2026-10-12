require "test_helper"
require "minitest/mock"

class ClerkAuthenticationTest < ActiveSupport::TestCase
  test "Clerkセッションがない場合は未認証と判定する" do
    controller = ApplicationController.new
    proxy = Struct.new(:user?).new(false)

    controller.stub(:clerk, proxy) do
      assert_not controller.clerk_authenticated?
      assert_nil controller.current_clerk_user
      assert_nil controller.current_app_user
    end
  end

  test "Clerkセッションがある場合はSDKユーザーからアプリユーザーを解決する" do
    controller = ApplicationController.new
    clerk_user = Struct.new(:id, :primary_email_address_id, :email_addresses).new(
      "user_clerk_session",
      "email_session",
      [ Struct.new(:id, :email_address).new("email_session", "session@example.com") ]
    )
    proxy = Struct.new(:user?, :user).new(true, clerk_user)

    controller.stub(:clerk, proxy) do
      assert controller.clerk_authenticated?
      assert_equal clerk_user, controller.current_clerk_user
      assert_equal "user_clerk_session", controller.current_app_user.clerk_user_id
    end
  end
end
