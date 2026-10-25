require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "トップページが表示される" do
    get root_path

    assert_response :success
    assert_select '[data-controller="clerk-auth"]' do
      assert_select '[data-clerk-auth-target="signIn"]'
      assert_select '[data-clerk-auth-sign-in-url-value="/"]'
      assert_select '[data-clerk-auth-sign-up-url-value="/"]'
      assert_select '[data-clerk-auth-redirect-url-value="/games"]'
    end
    assert_select 'img[alt="ツミクエスト"]'
    assert_select "nav", count: 0
  end

  test "個別のサインイン・サインアップGETルートは存在しない" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/sign_in", method: :get)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/sign_up", method: :get)
    end
  end
end