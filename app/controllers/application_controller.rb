class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :check_activated

  private

  def check_activated
    if user_signed_in? && !current_user.activated?
      sign_out current_user
      redirect_to root_path, alert: "アカウントの有効化が必要です。登録時に送信されたメールのリンクから有効化してください"
    end
  end

  def after_sign_in_path_for(resource)
    games_path
  end
end