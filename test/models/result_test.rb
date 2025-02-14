require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "can create a result" do
    result = Result.new(user: users(:one), event: events(:one), time: 3600)
    assert result.valid?
  end

  test "result must have an event" do
    result = Result.new(user: users(:one), time: 3600)
    assert_not result.valid?
  end

  test "result doesn't need a user" do
    result = Result.new(event: events(:one), time: 3600)
    assert result.valid?
  end

  test "result doesn't need a time" do
    result = Result.new(user: users(:one), event: events(:one))
    assert result.valid?
  end

  test "result can't be missing both user and time" do
    result = Result.new(event: events(:one))
    assert_not result.valid?
  end

  test "result must have an event in database" do
    result = results(:first)
    result.event = nil
    assert_raises(ActiveRecord::NotNullViolation) { result.save(validate: false) }
  end

  test "result doesn't need a user in database" do
    result = results(:first)
    result.user = nil
    assert result.save(validate: false)
  end

  test "result doesn't need a time in database" do
    result = results(:first)
    result.time = nil
    assert result.save(validate: false)
  end

  test "result can't be missing both user and time in database" do
    result = results(:first)
    result.time = nil
    result.user = nil
    assert_raise(ActiveRecord::StatementInvalid) { result.save(validate: false) }
  end

  test "time must not be too short" do
    result = Result.new(user: users(:one), event: events(:one), time: 360)
    assert_not result.valid?
  end

  test "time must not be too long" do
    result = Result.new(user: users(:one), event: events(:one), time: 7_500)
    assert_not result.valid?
  end

  test "place is calculated correctly" do
    assert results(:first).place == 1
    assert results(:second).place == 2
  end

  test "valid times less than an hour are converted correctly" do
    result = results(:first)

    result.time_string=("29:31")
    assert result.time = 871
  end

  test "valid times over an hour are converted correctly" do
    result = results(:first)

    result.time_string=("1:07:51")
    assert result.time = 4_071
  end

  test "times with minutes greater than 59 are invalid" do
    result = results(:first)

    result.time_string=("67:51")
    assert_not result.valid?
  end

  test "times with seconds greater than 59 are invalid" do
    result = results(:first)

    result.time_string=("29:61")
    assert_not result.valid?
  end

  test "adding user result increments result count" do
    user = users(:one)
    assert user.results_count == 1

    Result.create(user: users(:one), event: events(:two), time: 3500)

    assert user.results_count == 2
  end

  test "first result has first_timer flag set" do
    user = users(:one)

    assert user.results.first.first_timer?
  end

  test "new fastest result has pb flag set" do
    user = users(:one)
    previous_best = user.results.first.time

    result = Result.create(user: users(:one), event: events(:two), time: previous_best - 10)

    assert result.pb?
  end
end
