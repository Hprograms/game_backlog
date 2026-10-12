class User < ApplicationRecord
  class ClerkIdentityConflict < StandardError; end

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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

      if where(email: email).exists?
        raise ClerkIdentityConflict, "Email is already associated with a different application user"
      end

      create!(
        clerk_user_id: clerk_user_id,
        email: email,
        password: SecureRandom.urlsafe_base64(32)
      )
    end
  rescue ActiveRecord::RecordNotUnique
    find_by(clerk_user_id: clerk_user_id) ||
      raise(ClerkIdentityConflict, "Clerk identity conflicts with an existing application user")
  end

  attr_accessor :activation_token

  before_create :create_activation_digest

  def create_activation_digest
    self.activation_token  = SecureRandom.urlsafe_base64
    self.activation_digest = BCrypt::Password.create(activation_token)
  end

  def authenticated?(token)
    BCrypt::Password.new(activation_digest).is_password?(token)
  end
end
