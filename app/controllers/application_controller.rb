class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :check_activated

  include Clerk::Authenticatable

  helper_method :clerk_authenticated?, :current_clerk_user, :current_app_user

  def clerk_authenticated?
    clerk&.user? || false
  end

  def current_clerk_user
    return unless clerk_authenticated?

    @current_clerk_user ||= clerk.user
  end

  def current_app_user
    return unless current_clerk_user

    @current_app_user ||= User.find_or_create_for_clerk!(current_clerk_user)
  end

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
