require "test_helper"

class EventInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @guest = create_user(first_name: "UniqueGuest")
    @circle = create_circle(owner: @host, private: true)
    @event = create_event(host: @host, circles: [@circle], private: true)
  end

  test "host invites an individual who can respond without joining the circle" do
    sign_in @host
    get new_event_event_invitation_path(@event), params: { q: "UniqueGuest" }
    assert_response :success
    assert_select "button[aria-label='Invite #{@guest.full_name}']"

    assert_no_difference "UserCircle.count" do
      assert_difference ["UserEvent.count", "Notification.count"], 1 do
        post event_event_invitations_path(@event), params: { event_invitation: { user_id: @guest.id } }
      end
    end
    assert_response :see_other
    assert @event.rsvp_of(@guest).invited?
    assert @guest.notifications.last.event_invitation?

    sign_in @guest
    get notifications_path
    assert_select ".event-invitation", text: /#{Regexp.escape(@event.title)}/
    get event_path(@event)
    assert_response :success
    assert_not_includes response.body, "Invite people"
    assert_not CirclePolicy.new(@guest, @circle).show?

    post event_user_events_path(@event), params: { user_event: { status: "going" } }
    assert_response :see_other
    follow_redirect!
    assert_response :success
    assert_select ".rsvp-button.is-active[aria-pressed='true']", text: "Going"
    assert_includes response.body, "EventChatroomChannel"
    get notifications_path
    assert_select ".event-invitation", count: 0
  end

  test "duplicate invites do not reset a response or send more notifications" do
    @event.invite!(@guest, actor: @host).update!(status: :declined)
    sign_in @host
    assert_no_difference ["UserEvent.count", "Notification.count"] do
      post event_event_invitations_path(@event), params: { event_invitation: { user_id: @guest.id } }
    end
    assert @event.rsvp_of(@guest).declined?
  end

  test "guests cannot search for or invite more people" do
    invited = @event.invite!(@guest, actor: @host)
    outsider = create_user
    sign_in @guest
    UserEvent.statuses.each_key do |status|
      invited.update!(status: status)
      get new_event_event_invitation_path(@event)
      assert_redirected_to root_path
      assert_no_difference ["UserEvent.count", "Notification.count"] do
        post event_event_invitations_path(@event), params: { event_invitation: { user_id: outsider.id } }
      end
      assert_redirected_to root_path
    end
  end

  test "existing guests are excluded from search and results are bounded" do
    @event.invite!(@guest, actor: @host)
    sign_in @host
    get new_event_event_invitation_path(@event), params: { q: "UniqueGuest" }
    assert_response :success
    assert_select "button[aria-label='Invite #{@guest.full_name}']", count: 0
    21.times { create_user(first_name: "Matching") }
    get new_event_event_invitation_path(@event), params: { q: "Matching" }
    assert_select ".invitation-card", count: 20
  end

  test "the retired bulk-circle invitation endpoint is not routed" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/events/#{@event.id}/circle_events", method: :post)
    end
  end
end
