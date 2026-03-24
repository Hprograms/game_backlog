class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      if user.persisted?
        UserMailer.activation_email(user).deliver_now
      end
    end
  end
end