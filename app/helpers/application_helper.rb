module ApplicationHelper
  def clerk_frontend_api_url
    publishable_key = Clerk.configuration.publishable_key
    unless publishable_key.present? && Clerk::Utils.valid_publishable_key?(publishable_key)
      raise Clerk::ConfigurationError, "A valid CLERK_PUBLISHABLE_KEY is required to load ClerkJS"
    end

    frontend_api = Clerk::Utils.decode_publishable_key(publishable_key).delete_suffix("$")
    "https://#{frontend_api}"
  end
end
