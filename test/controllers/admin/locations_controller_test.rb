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

  test "should attach a gpx file on update" do
    patch admin_location_url(@location), params: { location: { gpx_file: fixture_file_upload("course.gpx", "application/gpx+xml") } }

    assert_redirected_to admin_location_url(@location)
    assert @location.reload.gpx_file.attached?
  end

  test "should reject a non gpx file on update" do
    patch admin_location_url(@location), params: { location: { gpx_file: fixture_file_upload("not_a_route.txt", "text/plain") } }

    assert_response :unprocessable_entity
    assert_not @location.reload.gpx_file.attached?
  end

  test "edit form includes a gpx file field" do
    get edit_admin_location_url(@location)

    assert_select "input[type=file][name=?]", "location[gpx_file]"
  end

  test "show displays the attached gpx file" do
    @location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/gpx+xml")

    get admin_location_url(@location)

    assert_select "a[href=?]", course_gpx_path(@location), text: /course\.gpx/
  end
end
