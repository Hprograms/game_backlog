class User < ApplicationRecord
  class ClerkIdentityConflict < StandardError; end

  has_many :games, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :user_trophies, dependent: :destroy
  has_many :trophies, through: :user_trophies

  validates :name, length: { maximum: 15 }, allow_blank: true

  def exp_required_for_next_level
    level < 100 ? (30 * level) + 70 : 3_000
  end

  def total_exp_required_for_level(target_level)
    levels_before_target = [ target_level - 1, 0 ].max
    levels_up_to_99 = [ levels_before_target, 99 ].min
    exp_through_level_99 = (30 * levels_up_to_99 * (levels_up_to_99 + 1) / 2) +
      (70 * levels_up_to_99)
    exp_after_level_99 = [ levels_before_target - 99, 0 ].max * 3_000

    exp_through_level_99 + exp_after_level_99
  end

  def add_exp!(amount, game = nil)
    with_lock do
      total_exp = exp + amount
      new_level = level
      new_level += 1 while total_exp >= total_exp_required_for_level(new_level + 1)

      leveled_up = new_level > level
      update!(exp: total_exp, level: new_level)
      create_activity("level_up", game) if leveled_up
      unlock_trophies!(game)
    end
  end

  def unlock_trophies!(game = nil)
    newly_unlocked = []
    owned_trophy_ids = user_trophies.pluck(:trophy_id)
    cleared_games = games.where(status: "クリア済")
    cleared_counts_by_genre = cleared_games.group(:genre).count
    cleared_count = cleared_counts_by_genre.values.sum
    total_play_time = cleared_games.sum(:play_time)
    has_100_hour_clear = cleared_games.where("play_time >= ?", 100 * 60).exists?

    eligible_codes = []
    eligible_codes << "level_10" if level >= 10
    eligible_codes << "level_30" if level >= 30
    eligible_codes << "level_50" if level >= 50
    eligible_codes << "level_100" if level >= 100
    eligible_codes << "clear_1" if cleared_count >= 1
    eligible_codes << "clear_10" if cleared_count >= 10
    eligible_codes << "clear_30" if cleared_count >= 30
    eligible_codes << "clear_50" if cleared_count >= 50
    eligible_codes << "play_time_100" if has_100_hour_clear
    eligible_codes << "total_play_time_500" if total_play_time >= 500
    eligible_codes << "genre_rpg_5" if cleared_counts_by_genre.fetch("RPG", 0) >= 5
    eligible_codes << "genre_action_5" if cleared_counts_by_genre.fetch("アクション", 0) >= 5

    trophies_by_code = Trophy.where(code: eligible_codes).index_by(&:code)

    eligible_codes.each do |code|
      trophy = trophies_by_code[code]
      raise ActiveRecord::RecordNotFound, "Trophy with code '#{code}' not found" unless trophy
      next if owned_trophy_ids.include?(trophy.id)

      user_trophies.create!(trophy: trophy, unlocked_at: Time.current)
      create_activity("trophy_unlocked", game)
      newly_unlocked << trophy
    end

    newly_unlocked
  end

  def self.find_or_create_for_clerk!(clerk_user)
    clerk_user_id = clerk_user&.id
    raise ArgumentError, "Clerk user must have an ID" if clerk_user_id.blank?

    existing_user = find_by(clerk_user_id: clerk_user_id)
    return existing_user if existing_user

    primary_email = Array(clerk_user.email_addresses).find do |email_address|
      email_address.id == clerk_user.primary_email_address_id
    end
    email = primary_email&.email_address&.strip&.downcase
    raise ArgumentError, "Clerk user must have a primary email address" if email.blank?

    transaction do
      existing_user = find_by(clerk_user_id: clerk_user_id)
      next existing_user if existing_user

      user_by_email = find_by(email: email)
      if user_by_email
        user_by_email.update!(clerk_user_id: clerk_user_id)
        next user_by_email
      end

      create!(
        clerk_user_id: clerk_user_id,
        email: email
      )
    end
  rescue ActiveRecord::RecordNotUnique
    find_by(clerk_user_id: clerk_user_id) ||
      raise(ClerkIdentityConflict, "Clerk identity conflicts with an existing application user")
  end

  private

  def create_activity(action_type, game)
    return unless game

    Activity.create!(
      user_id: id,
      game_id: game.id,
      action_type: action_type,
      occurred_at: Time.current
    )
  end
end
