class HomeController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    if user_signed_in?
      redirect_to games_path
    end
  end
end