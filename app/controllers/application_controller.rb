class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :authenticate_clerk_user!

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

  def authenticate_clerk_user!
    return if clerk_authenticated?

    respond_to do |format|
      format.html do
        redirect_to new_user_session_path, alert: "このページを表示するにはログインしてください"
      end
      format.any { head :unauthorized }
    end
  end
end
