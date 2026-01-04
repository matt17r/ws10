require "test_helper"

class HomeStatisticsTest < ActiveSupport::TestCase
  test "calculates confirmed registrations count" do
    assert_equal 3, Event.send(:confirmed_registrations_count)
  end

  test "calculates total participants count including results and volunteers" do
    assert_equal 3, Event.send(:total_participants_count)
  end

  test "calculates unique participants count without double counting" do
    assert_equal 3, Event.send(:unique_participants_count)
  end

  test "user with both result and volunteer record counts as one unique participant" do
    user = users(:one)
    event = events(:two)

    Volunteer.create!(event: event, user: user, role: "Marshal")

    assert_equal 3, Event.send(:unique_participants_count)
  end

  test "calculates total kilometres run" do
    assert_equal 20, Event.send(:total_kilometres_run)
  end

  test "calculates total time spent running in seconds" do
    assert_equal 4_900, Event.send(:total_time_spent_running)
  end

  test "location statistics includes quickest, average, and median times" do
    stats = Event.send(:location_statistics_data)

    bungarribee_stats = stats.find { |s| s[:location].slug == "bungarribee" }
    assert_not_nil bungarribee_stats

    assert_equal 2_400, bungarribee_stats[:quickest_time]
    assert_equal 2_450, bungarribee_stats[:average_time]
    assert_equal 2_500, bungarribee_stats[:median_time]
  end

  test "location statistics excludes locations with no completed results" do
    stats = Event.send(:location_statistics_data)

    nepean_stats = stats.find { |s| s[:location].slug == "nepean" }
    assert_nil nepean_stats

    parramatta_stats = stats.find { |s| s[:location].slug == "parramatta" }
    assert_nil parramatta_stats
  end

  test "location statistics handles single result correctly" do
    user = users(:one)
    event = events(:two)

    Result.create!(event: event, user: user, time: 3_000)

    stats = Event.send(:location_statistics_data)
    nepean_stats = stats.find { |s| s[:location].slug == "nepean" }

    assert_not_nil nepean_stats
    assert_equal 3_000, nepean_stats[:quickest_time]
    assert_equal 3_000, nepean_stats[:average_time]
    assert_equal 3_000, nepean_stats[:median_time]
  end

  test "calculates statistics with empty database" do
    Result.destroy_all
    Volunteer.destroy_all
    User.destroy_all

    stats = Event.send(:calculate_home_statistics)

    assert_equal 0, stats[:confirmed_registrations]
    assert_equal 0, stats[:total_participants]
    assert_equal 0, stats[:unique_participants]
    assert_equal [], stats[:location_statistics]
    assert_equal 0, stats[:total_kilometres]
    assert_equal 0, stats[:total_time_seconds]
  end

  test "home_statistics returns complete hash with expected keys" do
    stats = Event.home_statistics

    assert_kind_of Hash, stats
    assert_includes stats.keys, :confirmed_registrations
    assert_includes stats.keys, :total_participants
    assert_includes stats.keys, :unique_participants
    assert_includes stats.keys, :location_statistics
    assert_includes stats.keys, :total_kilometres
    assert_includes stats.keys, :total_time_seconds
  end

  test "home_statistics uses cache" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    Event.invalidate_home_statistics_cache

    assert_not Rails.cache.exist?("home_statistics")

    first_call = Event.home_statistics
    assert Rails.cache.exist?("home_statistics")

    second_call = Event.home_statistics
    assert_equal first_call, second_call
  ensure
    Rails.cache = original_cache
  end

  test "invalidate_home_statistics_cache removes cache" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    Event.home_statistics
    assert Rails.cache.exist?("home_statistics")

    Event.invalidate_home_statistics_cache
    assert_not Rails.cache.exist?("home_statistics")
  ensure
    Rails.cache = original_cache
  end

  test "ignores results without times when calculating kilometres and time" do
    user = users(:one)
    event = events(:two)

    Result.create!(event: event, user: user, time: nil)

    assert_equal 20, Event.send(:total_kilometres_run)
    assert_equal 4_900, Event.send(:total_time_spent_running)
  end

  test "unique participants includes users with only volunteer records" do
    user_count_before = Event.send(:unique_participants_count)

    new_user = User.create!(
      email_address: "volunteer@example.com",
      password: "password",
      name: "Volunteer Only",
      confirmed_at: 1.day.ago
    )

    Volunteer.create!(event: events(:one), user: new_user, role: "Timer")

    assert_equal user_count_before + 1, Event.send(:unique_participants_count)
  end

  test "location statistics calculates median correctly for odd number of times" do
    user = users(:one)
    event_two = events(:two)

    Result.create!(event: event_two, user: user, time: 2_000)
    Result.create!(event: event_two, user: users(:two), time: 3_000)
    Result.create!(event: event_two, user: users(:three), time: 4_000)

    stats = Event.send(:location_statistics_data)
    nepean_stats = stats.find { |s| s[:location].slug == "nepean" }

    assert_equal 3_000, nepean_stats[:median_time]
  end

  test "calculates overall fastest time" do
    assert_equal 2_400, Event.send(:overall_fastest_time)
  end

  test "calculates overall average time" do
    assert_equal 2_450, Event.send(:overall_average_time)
  end

  test "calculates overall median time" do
    assert_equal 2_500, Event.send(:overall_median_time)
  end

  test "overall fastest time returns nil when no results" do
    Result.destroy_all

    assert_nil Event.send(:overall_fastest_time)
  end

  test "overall average time returns nil when no results" do
    Result.destroy_all

    assert_nil Event.send(:overall_average_time)
  end

  test "overall median time returns nil when no results" do
    Result.destroy_all

    assert_nil Event.send(:overall_median_time)
  end

  test "overall pace statistics with single result" do
    Result.where.not(time: nil).destroy_all
    Result.create!(event: events(:one), user: users(:one), time: 3_000)

    assert_equal 3_000, Event.send(:overall_fastest_time)
    assert_equal 3_000, Event.send(:overall_average_time)
    assert_equal 3_000, Event.send(:overall_median_time)
  end

  test "home_statistics includes pace statistics" do
    stats = Event.home_statistics

    assert_includes stats.keys, :fastest_time
    assert_includes stats.keys, :average_time
    assert_includes stats.keys, :median_time
  end
end
