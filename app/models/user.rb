class User < ApplicationRecord
  class ClerkIdentityConflict < StandardError; end

  has_many :games, dependent: :destroy

  def self.find_or_create_for_clerk!(clerk_user)
    clerk_user_id = clerk_user&.id
    raise ArgumentError, "Clerk user must have an ID" if clerk_user_id.blank?

    existing_user = find_by(clerk_user_id: clerk_user_id)
    return existing_user if existing_user

    primary_email = Array(clerk_user.email_addresses).find do |email_address|
      email_address.id == clerk_user.primary_email_address_id
    end
    email = primary_email&.email_address&.strip&.downcase
    raise ArgumentError, "Clerk user must have a primary email address" if email.blank?

    transaction do
      existing_user = find_by(clerk_user_id: clerk_user_id)
      next existing_user if existing_user

      user_by_email = find_by(email: email)
      if user_by_email
        user_by_email.update!(clerk_user_id: clerk_user_id)
        next user_by_email
      end

      create!(
        clerk_user_id: clerk_user_id,
        email: email
      )
    end
  rescue ActiveRecord::RecordNotUnique
    find_by(clerk_user_id: clerk_user_id) ||
      raise(ClerkIdentityConflict, "Clerk identity conflicts with an existing application user")
  end
end
