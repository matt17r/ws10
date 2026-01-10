namespace :badges do
  desc "Award badges to all users based on their current participation"
  task award_all: :environment do
    puts "Checking and awarding badges for all users..."

    awarded_count = 0
    User.find_each do |user|
      newly_earned = BadgeEligibilityChecker.new(user).check_and_award_all

      if newly_earned.any?
        puts "  #{user.display_name}: awarded #{newly_earned.map(&:name).join(", ")}"
        awarded_count += newly_earned.count
      end
    end

    puts "\nCompleted! Awarded #{awarded_count} badges across #{User.count} users."
  end

  desc "Award badges to a specific user by email"
  task :award_for_user, [ :email ] => :environment do |t, args|
    unless args[:email]
      puts "Usage: bin/rails badges:award_for_user[user@example.com]"
      exit
    end

    user = User.find_by(email_address: args[:email])
    unless user
      puts "User not found: #{args[:email]}"
      exit
    end

    newly_earned = BadgeEligibilityChecker.new(user).check_and_award_all

    if newly_earned.any?
      puts "Awarded badges to #{user.display_name}:"
      newly_earned.each do |badge|
        puts "  - #{badge.name}: #{badge.description}"
      end
    else
      puts "No new badges awarded to #{user.display_name}"
    end
  end
end
