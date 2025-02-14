require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "can create an event" do
    event = Event.new(date: Date.new, number: 42, location: "The Moon")
    assert event.valid?
  end

  test "event must have date" do
    event = Event.new(number: 42, location: "The Moon")
    assert_not event.valid?
  end

  test "event must have number" do
    event = Event.new(date: Date.new, location: "The Moon")
    assert_not event.valid?
  end

  test "event must have location" do
    event = Event.new(date: Date.new, number: 42)
    assert_not event.valid?
  end

  test "event must have date in database" do
    event = events(:one)
    event.date = nil
    assert_raises(ActiveRecord::NotNullViolation) { event.save(validate: false) }
  end

  test "event must have number in database" do
    event = events(:one)
    event.number = nil
    assert_raises(ActiveRecord::NotNullViolation) { event.save(validate: false) }
  end

  test "event must have location in database" do
    event = events(:one)
    event.location = nil
    assert_raises(ActiveRecord::NotNullViolation) { event.save(validate: false) }
  end
end
