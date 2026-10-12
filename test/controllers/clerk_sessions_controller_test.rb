require "test_helper"
require "minitest/mock"
require "base64"

class ClerkSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clerk_configuration = Clerk.configuration
    @publishable_key = "pk_test_#{Base64.strict_encode64('clerk.test$')}"
  end

  test "ログイン画面にClerkのサインインUIを表示する" do
    @clerk_configuration.stub(:publishable_key, @publishable_key) do
      get new_user_session_path

      assert_response :success
      assert_select '[data-controller="clerk-auth"]' do
        assert_select '[data-clerk-auth-target="signIn"]'
        assert_select '[data-clerk-auth-sign-in-url-value="/users/sign_in"]'
        assert_select '[data-clerk-auth-sign-up-url-value="/users/sign_up"]'
        assert_select '[data-clerk-auth-redirect-url-value="/games"]'
      end
      assert_includes response.body, "https://clerk.test/npm/@clerk/ui@1/dist/ui.browser.js"
      assert_includes response.body, "https://clerk.test/npm/@clerk/clerk-js@6/dist/clerk.browser.js"
      assert_includes response.body, @publishable_key
    end
  end

  test "新規登録画面にClerkのサインアップUIを表示する" do
    @clerk_configuration.stub(:publishable_key, @publishable_key) do
      get new_user_registration_path

      assert_response :success
      assert_select '[data-controller="clerk-auth"]' do
        assert_select '[data-clerk-auth-target="signUp"]'
        assert_select '[data-clerk-auth-sign-in-url-value="/users/sign_in"]'
        assert_select '[data-clerk-auth-sign-up-url-value="/users/sign_up"]'
        assert_select '[data-clerk-auth-redirect-url-value="/games"]'
      end
    end
  end

  test "Clerk公開鍵が設定されていない場合は画面表示に失敗する" do
    @clerk_configuration.stub(:publishable_key, nil) do
      assert_raises(Clerk::ConfigurationError) do
        get new_user_session_path
      end
    end
  end

  test "Clerk認証済みならログイン画面からゲーム一覧へ遷移する" do
    clerk_proxy = Struct.new(:user?).new(true)
    authenticate_request = Object.new
    authenticate_request.define_singleton_method(:resolve) do |env|
      env["clerk"] = clerk_proxy
      [ nil, {}, [] ]
    end

    @clerk_configuration.stub(:publishable_key, @publishable_key) do
      Clerk::AuthenticateRequest.stub(:new, ->(_context) { authenticate_request }) do
        get new_user_session_path
      end
    end

    assert_redirected_to games_path
  end

  test "旧認証のログイン・登録・ログアウト・有効化ルートは無効" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/sign_in", method: :post)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users", method: :post)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/sign_out", method: :delete)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/account_activations/1/edit", method: :get)
    end
  end

  test "Clerk公開鍵からフロントエンドAPIのURLを生成する" do
    @clerk_configuration.stub(:publishable_key, @publishable_key) do
      assert_equal "https://clerk.test", ApplicationController.helpers.clerk_frontend_api_url
    end
  end
end
