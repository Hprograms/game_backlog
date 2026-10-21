require "test_helper"
require "minitest/mock"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @clerk_user = clerk_user_record("user_clerk_profiles_test", "profiles@example.com")
    @user = User.create!(
      email: "profiles@example.com",
      clerk_user_id: @clerk_user.id
    )
  end

  test "名前未設定でも名前設定画面を表示できる" do
    with_clerk_session do
      get edit_profile_path
    end

    assert_response :success
    assert_select ".profile-setup-title", text: "あなたの なまえを おしえてください"
    assert_select 'input[name="user[name]"][maxlength="15"]'
    assert_select ".profile-setup-cancel", count: 0
  end

  test "名前設定済みなら設定画面からホームへ戻れる" do
    @user.update!(name: "以前の名前")

    with_clerk_session do
      get edit_profile_path
    end

    assert_response :success
    assert_select ".profile-setup-actions" do
      assert_select "a.profile-setup-cancel[href='#{root_path}']", text: "もどる", index: 0
      assert_select "input.profile-setup-submit", index: 1
    end
  end

  test "名前設定に成功したらホームへ戻る" do
    with_clerk_session do
      patch profile_path, params: { user: { name: "勇者アリス" } }
    end

    assert_redirected_to root_path
    assert_equal "勇者アリス", @user.reload.name
    assert_equal "冒険の書に 名前を 刻んだ！", flash[:notice]
  end

  test "15文字を超える名前は保存せず設定画面を再表示する" do
    with_clerk_session do
      patch profile_path, params: { user: { name: "あ" * 16 } }
    end

    assert_response :unprocessable_entity
    assert_nil @user.reload.name
    assert_select ".profile-setup-errors"
  end

  private

  def clerk_user_record(id, email)
    email_address_id = "email_#{id}"
    Struct.new(:id, :primary_email_address_id, :email_addresses).new(
      id,
      email_address_id,
      [ Struct.new(:id, :email_address).new(email_address_id, email) ]
    )
  end

  def with_clerk_session
    proxy = Struct.new(:user?, :user).new(true, @clerk_user)
    resolver = Object.new
    resolver.define_singleton_method(:resolve) do |env|
      env["clerk"] = proxy
      [ nil, {}, [] ]
    end

    Clerk::AuthenticateRequest.stub(:new, ->(_context) { resolver }) do
      yield
    end
  end
end
