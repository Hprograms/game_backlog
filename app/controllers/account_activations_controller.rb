class AccountActivationsController < ApplicationController
  skip_before_action :check_activated

  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(params[:id])
      user.update(activated: true, activated_at: Time.zone.now)
      sign_in user
      redirect_to games_path, notice: "アカウントが有効化されました！"
    else
      redirect_to root_path, alert: "有効化リンクが無効です"
    end
  end
end