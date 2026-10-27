class Game < ApplicationRecord
  attr_accessor :used_timer

  belongs_to :user
  has_many :activities, dependent: :destroy
  has_one_attached :image

  before_validation :set_play_time_from_parts, if: :play_time_parts_assigned?
  before_save :reset_earned_exp_results
  before_create :mark_legacy_status_as_awarded

  validates :title, presence: true
  validates :status, inclusion: { in: %w[未着手 プレイ中 クリア済] }
  validates :rating, numericality: { in: 1..5 }, allow_nil: true
  validate :play_time_cannot_be_decreased, on: :update

  def earned_exp_results
    @earned_exp_results ||= []
  end

  def play_time_hours=(hours)
    @play_time_hours = hours.presence&.to_i
  end

  def play_time_hours
    return @play_time_hours if instance_variable_defined?(:@play_time_hours)
    return if play_time.nil?

    play_time / 60
  end

  def play_time_minutes=(minutes)
    @play_time_minutes = minutes.presence&.to_i
  end

  def play_time_minutes
    return @play_time_minutes if instance_variable_defined?(:@play_time_minutes)
    return if play_time.nil?

    play_time % 60
  end

  after_save :award_play_time_exp, if: -> { saved_change_to_play_time? }
  after_save :award_exp_for_clear, if: -> { saved_change_to_status? && status == "クリア済" }
  after_save :unlock_trophies, if: -> { status == "クリア済" && (saved_change_to_status? || saved_change_to_play_time?) }
  after_save :record_activity

  private

  def reset_earned_exp_results
    @earned_exp_results = []
  end

  def play_time_parts_assigned?
    instance_variable_defined?(:@play_time_hours) || instance_variable_defined?(:@play_time_minutes)
  end

  def set_play_time_from_parts
    self.play_time = if play_time_hours.blank? && play_time_minutes.blank?
      nil
    else
      (play_time_hours.presence&.to_i || 0) * 60 + (play_time_minutes.presence&.to_i || 0)
    end
  end

  def mark_legacy_status_as_awarded
    self.awarded_play_time = play_time || 0
    self.exp_awarded_for_clear = true if status == "クリア済"
  end

  def play_time_cannot_be_decreased
    return unless play_time.present? && play_time_was.present? && play_time < play_time_was

    errors.add(:base, "プレイ時間を現在の記録より減らすことはできません")
  end

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

    user.unlock_trophies!(self)
  ensure
    @trophies_unlocked_during_save = false
  end

  def award_exp_for_clear
    updated = self.class.where(id: id, exp_awarded_for_clear: false).update_all(exp_awarded_for_clear: true)
    return unless updated == 1

    user.add_exp!(5_000, self)
    earned_exp_results << { type: :clear, exp: 5_000 }
    @trophies_unlocked_during_save = true
  end

  def award_play_time_exp
    current_awarded = awarded_play_time || 0
    return unless play_time.present? && play_time > current_awarded

    diff = play_time - current_awarded
    update_column(:awarded_play_time, play_time)

    base_exp = diff * 2
    user.add_exp!(base_exp, self)
    earned_exp_results << { type: :play_time, minutes: diff, exp: base_exp }

    if used_timer
      timer_bonus = base_exp / 5
      user.add_exp!(timer_bonus, self) if timer_bonus.positive?
      earned_exp_results << { type: :timer_bonus, exp: timer_bonus }
    end

    @trophies_unlocked_during_save = true
  end
end
