require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user visiting profile/results should be redirected to sign in" do
    get my_results_url

    assert_redirected_to sign_in_path
  end

  test "authenticated user visiting profile/results should be redirected to their own results page" do
    user = users(:one)
    sign_in_as(user)

    get my_results_url

    assert_redirected_to user_results_path(barcode: user.barcode_string)
  end

  test "after signing in, user should be redirected to profile/results if that was the requested page" do
    user = users(:one)

    get my_results_url
    assert_redirected_to sign_in_path

    post sign_in_url, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to my_results_url
  end

  test "show displays claimed position widget when user has claimed a position" do
    user = users(:one)
    sign_in_as(user)
    event = events(:draft_event)
    event.update!(status: "in_progress")
    event.finish_positions.create!(user: user, position: 42)

    get user_url

    assert_response :success
    assert_select "div.bg-blue-50", text: /position #42/
  end

  test "show does not display claimed position widget when user has no claimed position" do
    user = users(:one)
    sign_in_as(user)

    get user_url

    assert_response :success
    assert_select "div.bg-blue-50", count: 0
  end

  test "show does not display claimed position widget when event is not in progress" do
    user = users(:one)
    sign_in_as(user)
    event = events(:draft_event)
    event.update!(status: "draft")
    event.finish_positions.create!(user: user, position: 42)

    get user_url

    assert_response :success
    assert_select "div.bg-blue-50", count: 0
  end

  test "show does not display claimed position widget when event is finalised" do
    user = users(:one)
    sign_in_as(user)
    event = events(:draft_event)
    event.update!(status: "finalised")
    event.finish_positions.create!(user: user, position: 42)

    get user_url

    assert_response :success
    assert_select "div.bg-blue-50", count: 0
  end

  test "results page displays user badges" do
    user = users(:one)
    badge = badges(:centurion_bronze)
    event = events(:one)
    user.user_badges.create!(badge: badge, event: event)

    get user_results_path(barcode: user.barcode_string)

    assert_response :success
    assert_select "a[href=?]", badge_path(badge), title: badge.name
  end

  test "results page displays multiple badges from same family overlapping" do
    user = users(:one)
    bronze = badges(:centurion_bronze)
    silver = badges(:centurion_silver)
    gold = badges(:centurion_gold)
    event = events(:one)

    user.user_badges.create!(badge: bronze, event: event)
    user.user_badges.create!(badge: silver, event: event)
    user.user_badges.create!(badge: gold, event: event)

    get user_results_path(barcode: user.barcode_string)

    assert_response :success
    assert_select "a[href=?]", badge_path(gold)
    assert_select "a[href=?]", badge_path(silver)
    assert_select "a[href=?]", badge_path(bronze)
    assert_select "a.-ml-6", minimum: 1
  end

  test "results page does not display badges section when user has no badges" do
    user = users(:one)

    get user_results_path(barcode: user.barcode_string)

    assert_response :success
    assert_select "a[href^=?]", badges_path, count: 0
  end
end
