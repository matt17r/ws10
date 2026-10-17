require "test_helper"

class ActiveOriginOnlyTest < ActiveJob::TestCase
  class RecordingJob < ApplicationJob
    include ActiveOriginOnly

    def perform(log)
      log << :performed
    end
  end

  test "runs the job on the active origin" do
    log = []

    with_active_origin(true) { RecordingJob.perform_now(log) }

    assert_equal [ :performed ], log
  end

  test "skips the job on a host that isn't the active origin" do
    log = []

    with_active_origin(false) { RecordingJob.perform_now(log) }

    assert_empty log
  end

  test "treats every host as the active origin outside production" do
    assert ActiveOriginOnly.active_origin_check.call
  end

  test "every recurring job only runs on the active origin" do
    tasks = YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production")

    tasks.each_value do |task|
      assert_includes task.fetch("class").constantize.ancestors, ActiveOriginOnly, "#{task["class"]} must include ActiveOriginOnly"
    end
  end

  private

  def with_active_origin(active)
    original_check = ActiveOriginOnly.active_origin_check
    ActiveOriginOnly.active_origin_check = -> { active }
    yield
  ensure
    ActiveOriginOnly.active_origin_check = original_check
  end
end
