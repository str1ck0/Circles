require "test_helper"
require "minitest/mock"

class EventTest < ActiveSupport::TestCase
  test "end time must be strictly after start time" do
    event = create_event(host: create_user)
    [event.start_date - 1.hour, event.start_date].each do |invalid_end|
      event.end_date = invalid_end
      assert_not event.valid?
      assert_includes event.errors[:end_date], "must be after the start time"
    end
    event.end_date = event.start_date + 1.hour
    assert event.valid?
  end

  test "missing dates produce validation errors without raising" do
    event = Event.new(user: create_user, title: "Chess", location: "Berlin")
    assert_not event.valid?
    assert event.errors[:start_date].any?
    assert event.errors[:end_date].any?
  end

  test "a failed notification rolls back the invitation" do
    host = create_user
    invitee = create_user
    event = create_event(host: host)
    Notification.stub(:notify, ->(**) { raise "notification failure" }) do
      assert_no_difference "UserEvent.count" do
        assert_raises(RuntimeError) { event.invite!(invitee, actor: host) }
      end
    end
    assert_not event.attendee?(invitee)
  end
end
