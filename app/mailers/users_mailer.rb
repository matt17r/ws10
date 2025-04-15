class UsersMailer < ApplicationMailer
  def account_confirmation(user)
    @user = user
    mail subject: "Please confirm your WS10 email address", to: email_address_with_name(user.email_address, user.name)
  end
end
