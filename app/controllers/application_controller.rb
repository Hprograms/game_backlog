class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :check_activated

  private

  def check_activated
    if user_signed_in? && !current_user.activated?
      UserMailer.activation_email(current_user).deliver_now
      sign_out current_user
      redirect_to root_path, alert: "有効化メールを送信しました。メールのリンクからアカウントを有効化してください"
    end
  end

  def after_sign_in_path_for(resource)
    games_path
  end
end