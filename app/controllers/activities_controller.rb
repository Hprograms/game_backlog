class ActivitiesController < ApplicationController
  def index
    @page = (params[:page] || 1).to_i
    activities = current_user.activities
    @activities = activities.includes(:game).order(occurred_at: :desc).limit(20).offset((@page - 1) * 20)
    @next_page = @page + 1 if activities.count > @page * 20
  end
end
