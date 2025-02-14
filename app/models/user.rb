class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :results
  has_many :volunteers

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, :password, presence: true
end
