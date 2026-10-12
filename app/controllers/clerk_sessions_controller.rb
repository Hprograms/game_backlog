class ClerkSessionsController < ApplicationController
  skip_before_action :check_activated
  before_action :ensure_clerk_publishable_key!
  before_action :redirect_if_clerk_authenticated

  def sign_in
  end

  def sign_up
  end

  private

  def ensure_clerk_publishable_key!
    publishable_key = Clerk.configuration.publishable_key
    return if publishable_key.present? && Clerk::Utils.valid_publishable_key?(publishable_key)

    raise Clerk::ConfigurationError, "A valid CLERK_PUBLISHABLE_KEY is required to render Clerk authentication pages"
  end

  def redirect_if_clerk_authenticated
    redirect_to games_path if clerk_authenticated?
  end
end
