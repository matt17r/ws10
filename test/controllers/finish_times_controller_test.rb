require "test_helper"

class FinishTimesControllerTest < ActionDispatch::IntegrationTest
  test "can delete all finish times for an event" do
    sign_in_as users(:one)
    event = events(:draft_event)
    FinishTime.create!(event: event, position: 1, time: 1800)
    FinishTime.create!(event: event, position: 2, time: 1900)
    FinishTime.create!(event: event, position: 3, time: 2000)

    assert_equal 3, event.finish_times.count

    assert_difference "FinishTime.count", -3 do
      delete finish_times_destroy_all_path, params: { event_id: event.id }
    end

    assert_redirected_to dashboard_path
    assert_match(/Deleted 3 finish times/, flash[:notice])
  end

  test "should require admin to delete all finish times" do
    event = events(:draft_event)
    FinishTime.create!(event: event, position: 1, time: 1800)

    assert_no_difference "FinishTime.count" do
      delete finish_times_destroy_all_path, params: { event_id: event.id }
    end
    assert_response :not_found
  end
end
