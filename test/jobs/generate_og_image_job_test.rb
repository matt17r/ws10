require "test_helper"

class GenerateOgImageJobTest < ActiveJob::TestCase
  test "calls OgImageGeneratorService for the event" do
    event = events(:one)
    mock_service = Minitest::Mock.new
    mock_service.expect(:generate_and_attach, nil)

    OgImageGeneratorService.stub(:new, ->(e) { assert_equal event, e; mock_service }) do
      GenerateOgImageJob.perform_now(event.id)
    end

    mock_service.verify
  end
end
