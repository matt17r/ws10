require "test_helper"

class Admin::LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @location = locations(:bungarribee)
  end

  test "should get index" do
    get admin_locations_url
    assert_response :success
  end

  test "should get show using slug" do
    get admin_location_url(@location)
    assert_response :success
  end

  test "should get edit using slug" do
    get edit_admin_location_url(@location)
    assert_response :success
  end

  test "should update location using slug" do
    patch admin_location_url(@location), params: { location: { name: "Updated Name" } }
    assert_redirected_to admin_location_url(@location)
  end

  test "should destroy location without events using slug" do
    location_without_events = Location.create!(
      name: "Test Location",
      slug: "test-location",
      nickname: "Test",
      subtitle: "Test Subtitle",
      full_address: "123 Test St",
      start_point_description: "Test start",
      google_maps_url: "https://maps.google.com/test",
      apple_maps_url: "https://maps.apple.com/test",
      facilities: "Test facilities",
      course_description: "Test course",
      strava_route_url: "https://strava.com/test",
      strava_embed_id: "test123",
      strava_map_hash: "12.0/0.0/0.0"
    )

    assert_difference("Location.count", -1) do
      delete admin_location_url(location_without_events)
    end
    assert_redirected_to admin_locations_url
  end
end
