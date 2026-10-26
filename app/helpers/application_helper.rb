module ApplicationHelper
  def level_progress(user)
    level_exp_required = user.exp_required_for_next_level
    total_exp_at_level_start = user.total_exp_required_for_level(user.level)
    exp_into_level = (user.exp - total_exp_at_level_start).clamp(0, level_exp_required)

    {
      percentage: (exp_into_level * 100.0 / level_exp_required).round,
      current_exp: exp_into_level,
      required_exp: level_exp_required,
      remaining_exp: level_exp_required - exp_into_level
    }
  end

  def clerk_frontend_api_url
    publishable_key = Clerk.configuration.publishable_key
    unless publishable_key.present? && Clerk::Utils.valid_publishable_key?(publishable_key)
      raise Clerk::ConfigurationError, "A valid CLERK_PUBLISHABLE_KEY is required to load ClerkJS"
    end

    frontend_api = Clerk::Utils.decode_publishable_key(publishable_key).delete_suffix("$")
    "https://#{frontend_api}"
  end
end
