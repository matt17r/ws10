class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Reset your password", to: email_address_with_name(user.email_address, user.name)
  end
end
