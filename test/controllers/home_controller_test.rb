require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "トップページが表示される" do
    get root_path
    assert_response :success
  end
end