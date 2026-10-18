class Game < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  validates :title, presence: true
  validates :status, inclusion: { in: %w[未着手 プレイ中 クリア済] }
  validates :rating, numericality: { in: 1..5 }, allow_nil: true

  after_save :award_exp_for_clear, if: -> { saved_change_to_status? && status == "クリア済" }
  after_save :award_missing_play_time_exp, if: -> { saved_change_to_play_time? && status == "クリア済" }
  private

  def award_exp_for_clear
    bonus_awarded = play_time.present?
    updated = self.class.where(id: id, exp_awarded_for_clear: false).update_all(
      exp_awarded_for_clear: true,
      play_time_exp_awarded_for_clear: bonus_awarded
    )
    return unless updated == 1

    user.add_exp!(100 + (play_time || 0) * 10)
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
  end
end
