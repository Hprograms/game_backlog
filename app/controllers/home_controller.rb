class HomeController < ApplicationController
  skip_before_action :authenticate_clerk_user!

  def index
    if clerk_authenticated?
      redirect_to games_path
    end
  end
end
