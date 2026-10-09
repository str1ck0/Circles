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
    assert_not_includes response.body, "EventChatroomChannel"
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

  test "the host sees the chat, splitty and individual invitation controls" do
    create_circle(owner: @host, private: true)
    sign_in @host
    get event_path(@event)
    assert_response :success
    assert_includes response.body, "EventChatroomChannel"
    assert_includes response.body, "Splitty"
    assert_includes response.body, "Invite people"
  end

  test "creating a circle event does not automatically invite any members" do
    sign_in @host
    assert_difference "Event.count", 1 do
      assert_difference "UserEvent.count", 1 do
        assert_no_difference "Notification.count" do
          post events_path, params: { event: {
            title: "Chess", location: "Berlin", start_date: 1.week.from_now, end_date: 8.days.from_now,
            private: false, organising_circle_id: @circle.id
          } }
        end
      end
    end
    event = Event.order(:id).last
    assert_equal [@circle], event.circles
    assert event.rsvp_of(@host).going?
    assert_not event.attendee?(@circle_member)
    assert EventPolicy.new(@circle_member, event).show?
  end

  test "an event cannot be placed in someone else's circle" do
    sign_in @host
    assert_no_difference "Event.count" do
      assert_raises(ActiveRecord::RecordNotFound) do
        post events_path, params: { event: {
          title: "Chess", location: "Berlin", start_date: 1.week.from_now, end_date: 8.days.from_now,
          organising_circle_id: @foreign_circle.id
        } }
      end
    end
  end

  test "standalone events are invitation-only even if public is submitted" do
    sign_in @host
    post events_path, params: { event: {
      title: "Chess", location: "Berlin", start_date: 1.week.from_now, end_date: 8.days.from_now, private: false
    } }
    event = Event.order(:id).last
    assert_redirected_to event_path(event)
    assert event.private?
    assert_empty event.circles
    patch event_path(event), params: { event: { private: false } }
    assert event.reload.private?
  end

  test "starting an event from a circle preselects that circle" do
    sign_in @host
    get new_circle_event_path(@circle)
    assert_response :success
    assert_select "select[name='event[organising_circle_id]'] option[selected][value='#{@circle.id}']"
  end

  test "the host can open the edit form and sees a delete control" do
    sign_in @host
    get edit_event_path(@event)
    assert_response :success
    assert_includes response.body, "Save changes"
    assert_includes response.body, "Delete event"
  end

  test "guests cannot open the edit form" do
    sign_in @circle_member
    get edit_event_path(@event)
    assert_redirected_to root_path
  end

  test "updating without picking photos keeps the existing ones" do
    @event.photos.attach(io: File.open(file_fixture("avatar.png")), filename: "cover.png", content_type: "image/png")
    sign_in @host
    patch event_path(@event), params: { event: { title: "Renamed", photos: [""] } }
    assert_redirected_to event_path(@event)
    assert_equal "Renamed", @event.reload.title
    assert_equal 1, @event.photos.size
  end

  test "the host can delete an event, taking its guest list and Splitty with it" do
    payer = @event.user_events.find_by(user: @host)
    guest = UserEvent.create!(user: @circle_member, event: @event, status: :going)
    payment = Payment.create!(user_event: payer, description: "Pizza", amount: 20)
    payment.user_events = [guest]
    EventMessage.create!(event: @event, user: @host, content: "see you there")

    sign_in @host
    assert_difference ["Event.count", "Payment.count"], -1 do
      assert_difference "UserEvent.count", -2 do
        delete event_path(@event)
      end
    end
    assert_redirected_to root_path
    assert_equal 0, Splittee.count
  end

  test "guests cannot delete an event" do
    sign_in @circle_member
    assert_no_difference "Event.count" do
      delete event_path(@event)
    end
    assert_redirected_to root_path
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

  test "invalid event dates are rejected on creation and editing" do
    sign_in @host
    starts_at = 1.week.from_now
    assert_no_difference ["Event.count", "UserEvent.count", "Notification.count"] do
      post events_path, params: { event: {
        title: "Chess", location: "Berlin", start_date: starts_at,
        end_date: starts_at - 1.hour, organising_circle_id: @circle.id
      } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "must be after the start time"

    previous_end = @event.end_date
    patch event_path(@event), params: { event: { end_date: @event.start_date - 1.hour } }
    assert_response :unprocessable_entity
    assert_equal previous_end, @event.reload.end_date
  end
end
