class UserMailer < ApplicationMailer
  def activation_email(user)
    @user = user
    @activation_url = edit_account_activation_url(@user.activation_token, email: @user.email)
    mail(
      to: @user.email,
      from: "hika122025@gmail.com",
      subject: "アカウントを有効化してください"
    )
  end
end