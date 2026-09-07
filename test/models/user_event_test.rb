require "test_helper"

class UserEventTest < ActiveSupport::TestCase
  setup do
    @host = create_user
    @event = create_event(host: @host)
  end

  test "new guests start as invited" do
    guest = UserEvent.create!(user: create_user, event: @event)
    assert guest.invited?
  end

  test "a user can only be on the guest list once" do
    duplicate = UserEvent.new(user: @host, event: @event)
    assert_not duplicate.valid?
  end

  test "event counts RSVPs by status" do
    UserEvent.create!(user: create_user, event: @event, status: :maybe)
    UserEvent.create!(user: create_user, event: @event, status: :maybe)
    UserEvent.create!(user: create_user, event: @event)

    assert_equal({ "invited" => 1, "going" => 1, "maybe" => 2, "declined" => 0 }, @event.rsvp_counts)
    assert_equal 1, @event.going_count
  end
end
