namespace :badges do
  desc "Clean up duplicate badges created by the infinite loop bug"
  task cleanup_duplicates: :environment do
    puts "Cleaning up duplicate badges..."

    cleaned_count = 0

    User.find_each do |user|
      # For each singular repeatable badge family
      [ "monthly", "all-seasons", "palindrome", "perfect-10" ].each do |family|
        badge = Badge.find_by(badge_family: family)
        next unless badge

        # Calculate how many they should have
        checker = BadgeEligibilityChecker.new(user)
        should_have = checker.send(:count_eligible_for_family, family)

        # Get all their badges for this family
        user_badges = user.user_badges.where(badge: badge).order(:earned_at)

        # If they have more than they should, delete the extras
        if user_badges.count > should_have
          extras = user_badges.count - should_have
          user_badges.offset(should_have).destroy_all
          puts "  #{user.display_name} (#{family}): removed #{extras} duplicate badge(s)"
          cleaned_count += extras
        end
      end
    end

    puts "\nCompleted! Removed #{cleaned_count} duplicate badges."
  end
end
