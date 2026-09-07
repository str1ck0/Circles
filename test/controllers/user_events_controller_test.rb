require "test_helper"

class UserEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @circle_member = create_user
    @stranger = create_user
    @circle = create_circle(owner: @host, members: [@circle_member], private: true)
    @event = create_event(host: @host, circles: [@circle], private: false)
  end

  test "a circle member can RSVP going to the circle's public event, and the host is told" do
    sign_in @circle_member
    assert_difference ["UserEvent.count", "Notification.count"], 1 do
      post event_user_events_path(@event), params: { user_event: { status: "going" } }, as: :json
    end
    assert_response :success
    assert_equal "going", response.parsed_body["status"]
    assert_equal 2, response.parsed_body["counts"]["going"]
    assert @event.rsvp_of(@circle_member).going?
    assert @host.notifications.last.rsvp?
  end

  test "changing an RSVP updates the existing row" do
    sign_in @circle_member
    post event_user_events_path(@event), params: { user_event: { status: "going" } }, as: :json
    assert_no_difference "UserEvent.count" do
      post event_user_events_path(@event), params: { user_event: { status: "maybe" } }, as: :json
    end
    assert_response :success
    assert @event.rsvp_of(@circle_member).maybe?
    assert_equal({ "going" => 1, "maybe" => 1, "invited" => 0, "declined" => 0 }, response.parsed_body["counts"])
  end

  test "an invited guest can decline" do
    invited = create_user
    UserEvent.create!(user: invited, event: @event)
    sign_in invited
    post event_user_events_path(@event), params: { user_event: { status: "declined" } }
    assert_redirected_to event_path(@event)
    assert @event.rsvp_of(invited).declined?
  end

  test "unknown statuses are rejected" do
    sign_in @host
    post event_user_events_path(@event), params: { user_event: { status: "invited" } }, as: :json
    assert_response :unprocessable_entity
    assert @event.rsvp_of(@host).going?
  end

  test "a stranger is refused with JSON, not a crash" do
    sign_in @stranger
    assert_no_difference "UserEvent.count" do
      post event_user_events_path(@event), as: :json
    end
    assert_response :forbidden
    assert_equal "You don't have access to that.", response.parsed_body["error"]
  end
end
