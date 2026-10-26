module GamesHelper
  def format_play_time(minutes)
    return "未記録" if minutes.nil?

    hours, remaining_minutes = minutes.divmod(60)
    hours.positive? ? "#{hours}時間#{remaining_minutes}分" : "#{remaining_minutes}分"
  end
end
