require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home page when visiting root url" do
    get root_url
    assert_response :success
  end
end
