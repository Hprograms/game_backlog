class Game < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  validates :title, presence: true
  validates :status, inclusion: { in: %w[未着手 プレイ中 クリア済] }
  validates :rating, numericality: { in: 1..5 }, allow_nil: true

  after_save :award_exp_for_clear, if: -> { saved_change_to_status? && status == "クリア済" }
  after_save :award_missing_play_time_exp, if: -> { saved_change_to_play_time? && status == "クリア済" }
  after_save :unlock_trophies, if: -> { status == "クリア済" && (saved_change_to_status? || saved_change_to_play_time?) }
  after_save :record_activity

  private

  def record_activity
    if saved_change_to_status? && status == "プレイ中"
      create_activity_once("started")
    end

    if saved_change_to_status? && status == "クリア済"
      create_activity_once("cleared")
    end

    return unless status == "クリア済" && (saved_change_to_rating? || saved_change_to_memo?)

    activity = Activity.find_by(game_id: id, action_type: "reviewed")
    if activity
      activity.update!(occurred_at: Time.current)
    else
      Activity.create!(
        user_id: user_id,
        game_id: id,
        action_type: "reviewed",
        occurred_at: Time.current
      )
    end
  end

  def create_activity_once(action_type)
    return if Activity.exists?(game_id: id, action_type: action_type)

    Activity.create!(
      user_id: user_id,
      game_id: id,
      action_type: action_type,
      occurred_at: Time.current
    )
  end

  def unlock_trophies
    return if @trophies_unlocked_during_save

    user.unlock_trophies!
  ensure
    @trophies_unlocked_during_save = false
  end

  def award_exp_for_clear
    bonus_awarded = play_time.present?
    updated = self.class.where(id: id, exp_awarded_for_clear: false).update_all(
      exp_awarded_for_clear: true,
      play_time_exp_awarded_for_clear: bonus_awarded
    )
    return unless updated == 1

    user.add_exp!(100 + (play_time || 0) * 10)
    @trophies_unlocked_during_save = true
  end

  def award_missing_play_time_exp
    return if play_time.nil?

    updated = self.class.where(
      id: id,
      exp_awarded_for_clear: true,
      play_time_exp_awarded_for_clear: false
    ).update_all(play_time_exp_awarded_for_clear: true)
    return unless updated == 1

    user.add_exp!(play_time * 10)
    @trophies_unlocked_during_save = true
  end
end
