require "test_helper"

class AwardBadgesJobTest < ActiveJob::TestCase
  test "awards badges to event participants with results" do
    event = events(:one)
    user = users(:one)
    user.results.destroy_all

    # User must participate in THIS event for job to check them
    Result.create!(user: user, event: event)

    # Create 9 more results to reach 10 total and earn centurion badge
    created_events = []
    9.times do |i|
      event_for_results = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 200, status: "finalised")
      Result.create!(user: user, event: event_for_results)
      created_events << event_for_results
    end

    AwardBadgesJob.perform_now(event.id)

    assert user.badges.exists?(slug: "centurion-bronze")

    # Verify event_id is set correctly to the 10th result's event (the qualifying event)
    user_badge = user.user_badges.joins(:badge).find_by(badges: { slug: "centurion-bronze" })
    qualifying_event = created_events.last # The 10th result's event
    assert_equal qualifying_event.id, user_badge.event_id
  end

  test "awards badges to event participants with volunteers" do
    event = events(:one)
    user = users(:two)
    user.volunteers.destroy_all

    # User must volunteer in THIS event for job to check them
    Volunteer.create!(user: user, event: event, role: "Marshal")

    # Create 2 more volunteer records to reach 3 total and earn heart of gold badge
    created_events = []
    2.times do |i|
      event_for_volunteers = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 200, status: "finalised")
      Volunteer.create!(user: user, event: event_for_volunteers, role: "Marshal")
      created_events << event_for_volunteers
    end

    AwardBadgesJob.perform_now(event.id)

    assert user.badges.exists?(slug: "heart-of-gold-bronze")

    # Verify event_id is set correctly to the 3rd volunteer event (the qualifying event)
    user_badge = user.user_badges.joins(:badge).find_by(badges: { slug: "heart-of-gold-bronze" })
    qualifying_event = created_events.last # The 3rd volunteer event (bronze requires 1, so 1st volunteer event)
    # Wait, bronze heart-of-gold requires 1 volunteer, so events(:one) should be the qualifying event
    assert_equal event.id, user_badge.event_id
  end

  test "checks all users who participated in event" do
    event = events(:one)
    user_with_result = users(:one)
    user_with_volunteer = users(:two)

    user_with_result.results.destroy_all
    user_with_volunteer.volunteers.destroy_all
    user_with_volunteer.results.destroy_all

    # Create a result for user_with_result in the target event
    Result.create!(user: user_with_result, event: event)

    # Create a volunteer for user_with_volunteer in the target event
    Volunteer.create!(user: user_with_volunteer, event: event, role: "Marshal")

    # Make both eligible for a badge
    created_events = []
    9.times do |i|
      other_event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 200, status: "finalised")
      Result.create!(user: user_with_result, event: other_event)
      Volunteer.create!(user: user_with_volunteer, event: other_event, role: "Marshal")
      created_events << other_event
    end

    AwardBadgesJob.perform_now(event.id)

    # Both users participated in the event and should get badges
    assert user_with_result.badges.exists?(slug: "centurion-bronze")
    assert user_with_volunteer.badges.exists?(slug: "heart-of-gold-bronze")

    # Verify event_id is set correctly for both badges
    # Centurion bronze (10 results): qualifying event is the 10th result's event
    result_badge = user_with_result.user_badges.joins(:badge).find_by(badges: { slug: "centurion-bronze" })
    assert_equal created_events.last.id, result_badge.event_id

    # Heart of Gold bronze (1 volunteer): qualifying event is the 1st volunteer event
    volunteer_badge = user_with_volunteer.user_badges.joins(:badge).find_by(badges: { slug: "heart-of-gold-bronze" })
    assert_equal event.id, volunteer_badge.event_id
  end
end
