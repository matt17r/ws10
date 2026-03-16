require "test_helper"

class GenerateOgImageJobTest < ActiveJob::TestCase
  test "is enqueued from AwardBadgesJob after badges are awarded" do
    event = events(:one)
    assert_enqueued_with(job: GenerateOgImageJob) do
      AwardBadgesJob.perform_now(event.id)
    end
  end
end
