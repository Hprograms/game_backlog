require "test_helper"

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper

  self.fixture_table_names = []

  test "総EXPから現在のレベル内の進捗を計算する" do
    user = User.new(level: 2, exp: 151)

    assert_equal(
      {
        percentage: 39,
        current_exp: 51,
        required_exp: 130,
        remaining_exp: 79
      },
      level_progress(user)
    )
    assert_equal 39, level_progress(user)[:percentage]
  end

  test "EXPが次のレベル閾値に達したときに進捗を制限する" do
    user = User.new(level: 2, exp: 230)

    assert_equal 100, level_progress(user)[:percentage]
    assert_equal 0, level_progress(user)[:remaining_exp]
  end

  test "Lv100以降のプログレスバーは3000EXPを基準にする" do
    user = User.new(level: 100, exp: 156_930)

    assert_equal 50, level_progress(user)[:percentage]
    assert_equal 1_500, level_progress(user)[:current_exp]
    assert_equal 3_000, level_progress(user)[:required_exp]
  end
end
