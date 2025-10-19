require "test_helper"

class ResultsControllerTest < ActionDispatch::IntegrationTest
  test "should require admin to link results" do
    event = events(:draft_event)
    FinishPosition.create!(event: event, user: users(:one), position: 1)
    FinishTime.create!(event: event, time: 1800, position: 1)

    assert_no_difference "Result.count" do
      post result_link_path, params: { event_id: event.id }
    end
    assert_response :not_found
  end

  test "should require admin to delete results" do
    result = results(:first)

    assert_no_difference "Result.count" do
      delete result_path(result)
    end
    assert_response :not_found
  end

  test "linking creates results for positions with both finish position and time" do
    sign_in_as users(:one)
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: users(:one), position: 1)
    ft = FinishTime.create!(event: event, time: 1800, position: 1)

    assert_difference "Result.count", 1 do
      post result_link_path, params: { event_id: event.id }
      assert_response :redirect
    end

    result = Result.last
    assert_equal users(:one), result.user
    assert_equal 1800, result.time
  end

  test "linking creates results for positions with only finish position (participants without times)" do
    sign_in_as users(:one)
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: users(:one), position: 52)

    assert_difference "Result.count", 1 do
      post result_link_path, params: { event_id: event.id }
    end

    result = Result.last
    assert_equal users(:one), result.user
    assert_nil result.time
    assert_equal "P", result.place
    assert_equal "Participant", result.time_string
  end

  test "linking creates results for positions with only finish time (unknown finishers)" do
    sign_in_as users(:one)
    event = events(:draft_event)
    ft = FinishTime.create!(event: event, time: 1800, position: 1)

    assert_difference "Result.count", 1 do
      post result_link_path, params: { event_id: event.id }
    end

    result = Result.last
    assert_nil result.user
    assert_equal 1800, result.time
  end

  test "linking handles mixed scenario with matched, participant, and unknown finishers" do
    sign_in_as users(:one)
    event = events(:draft_event)

    FinishPosition.create!(event: event, user: users(:one), position: 1)
    FinishTime.create!(event: event, time: 1800, position: 1)

    FinishPosition.create!(event: event, user: users(:two), position: 52)

    FinishTime.create!(event: event, time: 2000, position: 3)

    assert_difference "Result.count", 3 do
      post result_link_path, params: { event_id: event.id }
    end

    matched_result = event.results.find_by(user: users(:one))
    assert_equal 1800, matched_result.time

    participant_result = event.results.find_by(user: users(:two))
    assert_nil participant_result.time
    assert_equal "P", participant_result.place

    unknown_result = event.results.find_by(time: 2000)
    assert_nil unknown_result.user
  end

  test "linking skips already linked results for known users" do
    sign_in_as users(:one)
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: users(:one), position: 1)
    ft = FinishTime.create!(event: event, time: 1800, position: 1)
    Result.create!(event: event, user: users(:one), time: 1800)

    assert_no_difference "Result.count" do
      post result_link_path, params: { event_id: event.id }
    end

    assert_redirected_to dashboard_path
    assert_match(/Skipped.*already linked/, flash[:alert])
  end

  test "linking allows multiple unknown finishers with the same time" do
    sign_in_as users(:one)
    event = events(:draft_event)

    FinishTime.create!(event: event, position: 18, time: 1800)
    FinishTime.create!(event: event, position: 19, time: 1800)

    assert_difference "Result.count", 2 do
      post result_link_path, params: { event_id: event.id }
    end

    results = event.results.where(time: 1800, user: nil)
    assert_equal 2, results.count
  end

  test "can delete all results for an event" do
    sign_in_as users(:one)
    event = events(:one)
    initial_count = event.results.count

    assert initial_count > 0, "Event should have results to delete"

    assert_difference "Result.count", -initial_count do
      delete results_destroy_all_path, params: { event_id: event.id }
    end

    assert_redirected_to dashboard_path
    assert_match(/Deleted #{initial_count} results/, flash[:notice])
  end

  test "should require admin to delete all results" do
    event = events(:one)
    initial_count = event.results.count

    assert_no_difference "Result.count" do
      delete results_destroy_all_path, params: { event_id: event.id }
    end
    assert_response :not_found
  end
end
