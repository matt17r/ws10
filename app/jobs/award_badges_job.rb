class AwardBadgesJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find(event_id)

    # Get all participants (results + volunteers)
    user_ids = event.results.where.not(user_id: nil).pluck(:user_id)
    user_ids += event.volunteers.pluck(:user_id)
    user_ids.uniq!

    User.where(id: user_ids).find_each do |user|
      BadgeEligibilityChecker.new(user, event_id: event_id).check_and_award_all
    end
  end
end
