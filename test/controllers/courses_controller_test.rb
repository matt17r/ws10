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

  test "gpx redirects to the attached file as a download" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/gpx+xml")

    get course_gpx_url(location)

    assert_response :redirect
    assert_match %r{/rails/active_storage/blobs/.+/course\.gpx}, response.location
    assert_match(/disposition=attachment/, response.location)
  end

  test "gpx returns not found when none is attached" do
    get course_gpx_url(locations(:bungarribee))

    assert_response :not_found
  end

  test "gpx does not require authentication" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/gpx+xml")

    get course_gpx_url(location)

    assert_response :redirect
    assert_no_match(/sign_in/, response.location)
  end

  test "show links to the gpx download from the load the route section" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/gpx+xml")

    get course_url(location)

    assert_select "section[aria-labelledby=load-the-route-bungarribee] a[href=?]", course_gpx_path(location), count: 1
    assert_select "a[href=?]", course_gpx_path(location), count: 1
  end

  test "show omits the gpx download when none is attached" do
    get course_url(locations(:bungarribee))

    assert_select "a[href=?]", course_gpx_path(locations(:bungarribee)), count: 0
  end

  test "show links to the strava route from the course description section" do
    location = locations(:bungarribee)

    get course_url(location)

    assert_select "#course-description-bungarribee ~ p a[href=?]", location.strava_route_url
  end

  test "show does not nest paragraphs" do
    get course_url(locations(:bungarribee))

    assert_select "p p", count: 0
  end

  test "show includes the unmarked course callout" do
    get course_url(locations(:nepean))

    assert_select "section[aria-labelledby=?]", "find-the-course-nepean"
  end

  test "show gives bungarribee extra guidance in its callout" do
    get course_url(locations(:bungarribee))
    bungarribee_callout = css_select("section[aria-labelledby=find-the-course-bungarribee]").text.squish

    get course_url(locations(:nepean))
    nepean_callout = css_select("section[aria-labelledby=find-the-course-nepean]").text.squish

    assert_operator bungarribee_callout.length, :>, nepean_callout.length
  end

  test "show has a load the route section that the callout links to" do
    get course_url(locations(:nepean))

    assert_select "section[aria-labelledby=find-the-course-nepean] a[href=?]", "#load-the-route-nepean"
    assert_select "#course-description-nepean ~ p a[href=?]", "#load-the-route-nepean"
    assert_select "section[aria-labelledby=load-the-route-nepean] h2#load-the-route-nepean"
  end
end
