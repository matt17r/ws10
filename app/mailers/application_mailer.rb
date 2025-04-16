class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name(Rails.application.credentials.dig(:smtp, :from), "WS10")
  layout "mailer"
end
