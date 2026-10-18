require "test_helper"

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper

  self.fixture_table_names = []

  test "総EXPから現在のレベル内の進捗を計算する" do
    user = User.new(level: 2, exp: 151)

    assert_equal(
      {
        percentage: 50,
        current_exp: 51,
        required_exp: 102,
        remaining_exp: 51
      },
      level_progress(user)
    )
  end

  test "EXPが次のレベル閾値に達したときに進捗を制限する" do
    user = User.new(level: 2, exp: 202)

    assert_equal 100, level_progress(user)[:percentage]
    assert_equal 0, level_progress(user)[:remaining_exp]
  end
end
