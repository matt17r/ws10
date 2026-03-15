class AddNewsletterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :newsletter_opt_in, :boolean, default: false, null: false
    add_column :users, :newsletter_subscribed, :boolean, default: false, null: false
  end
end
