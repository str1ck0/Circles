require "test_helper"

class CircleEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @friend = create_user
    @stranger = create_user
    @own_circle = create_circle(owner: @host, members: [@friend])
    @foreign_circle = create_circle(owner: @stranger, members: [create_user])
    @event = create_event(host: @host)
  end

  test "an attendee can attach their own circle, enrolling its members once" do
    sign_in @host
    assert_difference ["CircleEvent.count", "UserEvent.count"], 1 do
      post event_circle_events_path(@event), params: { circle_event: { circle_id: @own_circle.id } }
    end
    assert_redirected_to event_path(@event)
    assert @event.attendee?(@friend)

    assert_no_difference ["CircleEvent.count", "UserEvent.count"] do
      post event_circle_events_path(@event), params: { circle_event: { circle_id: @own_circle.id } }
    end
  end

  test "an attendee cannot attach a circle they don't belong to" do
    sign_in @host
    assert_no_difference ["CircleEvent.count", "UserEvent.count"] do
      post event_circle_events_path(@event), params: { circle_event: { circle_id: @foreign_circle.id } }
    end
    assert_redirected_to root_path
  end

  test "a non-attendee cannot attach anything" do
    sign_in @stranger
    assert_no_difference "CircleEvent.count" do
      post event_circle_events_path(@event), params: { circle_event: { circle_id: @foreign_circle.id } }
    end
    assert_redirected_to root_path
  end
end
