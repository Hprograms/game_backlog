require "test_helper"

class GamesHelperTest < ActiveSupport::TestCase
  include GamesHelper

  self.fixture_table_names = []

  test "プレイ時間を時間と分で表示する" do
    assert_equal "2時間10分", format_play_time(130)
    assert_equal "45分", format_play_time(45)
    assert_equal "1時間0分", format_play_time(60)
    assert_equal "未記録", format_play_time(nil)
  end
end
