class ActivitiesController < ApplicationController
  def index
    @activities = current_user.activities.includes(:game).order(occurred_at: :desc)
  end
end
