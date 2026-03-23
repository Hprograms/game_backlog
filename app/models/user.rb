class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :games, dependent: :destroy

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