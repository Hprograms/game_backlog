class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :authenticate_clerk_user!
  before_action :require_name_setup

  include Clerk::Authenticatable

  helper_method :clerk_authenticated?, :current_clerk_user, :current_app_user, :current_user

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

  def current_user
    current_app_user
  end

  private

  def require_name_setup
    redirect_to edit_profile_path if current_user.present? && current_user.name.blank?
  end

  def authenticate_clerk_user!
    return if clerk_authenticated?

    respond_to do |format|
      format.html do
        redirect_to root_path, alert: "このページを表示するにはログインしてください"
      end
      format.any { head :unauthorized }
    end
  end
end
