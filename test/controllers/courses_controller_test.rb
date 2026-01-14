require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  test "show displays location details" do
    get course_url(locations(:bungarribee))
    assert_response :success
    assert_select "h1", text: locations(:bungarribee).name
  end

  test "show with invalid slug returns not found" do
    get course_url("invalid-slug")
    assert_response :not_found
  end

  test "show displays next event badge when applicable" do
    # Create a future event for testing
    future_event = Event.create!(
      number: 999,
      date: 1.week.from_now,
      location: locations(:bungarribee)
    )

    get course_url(locations(:bungarribee))
    assert_response :success
    assert_select ".bg-primary", text: /Next Event/
  end
end
