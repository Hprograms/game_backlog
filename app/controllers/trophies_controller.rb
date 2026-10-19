class TrophiesController < ApplicationController
  def index
    @trophies = Trophy.order(:id)
    @unlocked_trophies_by_id = current_app_user.user_trophies.index_by(&:trophy_id)
  end
end
