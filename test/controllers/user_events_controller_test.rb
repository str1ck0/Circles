require "test_helper"

class UserEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @circle_member = create_user
    @stranger = create_user
    @circle = create_circle(owner: @host, members: [@circle_member], private: true)
    @event = create_event(host: @host, circles: [@circle], private: false)
  end

  test "a circle member can attend the circle's public event" do
    sign_in @circle_member
    assert_difference "UserEvent.count", 1 do
      post event_user_events_path(@event), as: :json
    end
    assert_response :success
    assert_equal 2, response.parsed_body["user_count"]
  end

  test "a stranger is refused with JSON, not a crash" do
    sign_in @stranger
    assert_no_difference "UserEvent.count" do
      post event_user_events_path(@event), as: :json
    end
    assert_response :forbidden
    assert_equal "You don't have access to that.", response.parsed_body["error"]
  end

  test "attending twice is refused" do
    sign_in @host
    assert_no_difference "UserEvent.count" do
      post event_user_events_path(@event)
    end
    assert_redirected_to root_path
  end
end
