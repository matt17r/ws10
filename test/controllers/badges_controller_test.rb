require "test_helper"

class BadgesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get badges_url
    assert_response :success
  end

  test "index should show all badge families" do
    get badges_url
    assert_response :success

    # Verify all 10 badge families are present
    assert_select "h3", text: /Centurion/
    assert_select "h3", text: /Traveller/
    assert_select "h3", text: /Consistent/
    assert_select "h3", text: /Simply the Best/
    assert_select "h3", text: /Heart of Gold/
    assert_select "h3", text: /Founding Member/
    assert_select "h3", text: /Monthly/
    assert_select "h3", text: /All Seasons/
    assert_select "h3", text: /Palindrome/
    assert_select "h3", text: /Perfect 10/
  end

  test "should get show" do
    badge = badges(:centurion_bronze)
    get badge_url(badge)
    assert_response :success
  end
end
