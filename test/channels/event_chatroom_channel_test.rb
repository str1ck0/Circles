require "test_helper"

class EventChatroomChannelTest < ActionCable::Channel::TestCase
  setup do
    @host = create_user
    @circle_member = create_user
    @circle = create_circle(owner: @host, members: [@circle_member])
    @event = create_event(host: @host, circles: [@circle], private: false)
  end

  test "attendees stream the event's chat" do
    stub_connection current_user: @host
    subscribe id: @event.id
    assert subscription.confirmed?
    assert_has_stream_for @event
  end

  test "circle members who haven't joined the event are rejected" do
    stub_connection current_user: @circle_member
    subscribe id: @event.id
    assert subscription.rejected?
  end
end
