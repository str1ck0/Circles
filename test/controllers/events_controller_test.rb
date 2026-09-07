require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @circle_member = create_user
    @stranger = create_user
    @circle = create_circle(owner: @host, members: [@circle_member], private: true)
    @foreign_circle = create_circle(owner: @stranger, private: true)
    @event = create_event(host: @host, circles: [@circle], private: false)
    @private_event = create_event(host: @host, circles: [@circle], private: true)
  end

  test "a circle member can view the circle's public event but not attend-only features" do
    sign_in @circle_member
    get event_path(@event)
    assert_response :success
    assert_includes response.body, "rsvp-group"
    assert_not_includes response.body, "event-chatroom-subscription"
    assert_not_includes response.body, "Splitty"
  end

  test "a circle member cannot view the circle's private event unless enrolled" do
    sign_in @circle_member
    get event_path(@private_event)
    assert_redirected_to root_path
  end

  test "a stranger cannot view any event" do
    sign_in @stranger
    get event_path(@event)
    assert_redirected_to root_path
  end

  test "the host sees the chat, splitty and circle-invite controls" do
    create_circle(owner: @host, private: true)
    sign_in @host
    get event_path(@event)
    assert_response :success
    assert_includes response.body, "event-chatroom-subscription"
    assert_includes response.body, "Splitty"
    assert_includes response.body, "Invite a circle"
  end

  test "creating an event ignores circles the creator doesn't belong to and enrols members" do
    sign_in @host
    assert_difference "Event.count", 1 do
      post events_path, params: { event: {
        title: "Picnic", location: "Berlin", start_date: 1.week.from_now, end_date: 8.days.from_now,
        private: false, circle_ids: [@circle.id, @foreign_circle.id]
      } }
    end
    event = Event.order(:id).last
    assert_equal [@circle], event.circles
    assert event.rsvp_of(@host).going?
    assert event.rsvp_of(@circle_member).invited?
    assert_not event.attendee?(@stranger)
  end

  test "only the host can update" do
    sign_in @circle_member
    patch event_path(@event), params: { event: { title: "Hijacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hijacked", @event.reload.title

    sign_in @host
    patch event_path(@event), params: { event: { title: "Renamed" } }
    assert_redirected_to event_path(@event)
    assert_equal "Renamed", @event.reload.title
  end
end
