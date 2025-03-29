class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :assignments
  has_many :roles, through: :assignments, dependent: :destroy

  has_many :results, dependent: :destroy
  has_many :volunteers, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, :display_name, :emoji, presence: true
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP}, presence: true

  def admin?
    roles.any? { |r| r.name == "Administrator" }
  end

  def organiser?
    roles.any? { |r| r.name == "Organiser" }
  end
end
