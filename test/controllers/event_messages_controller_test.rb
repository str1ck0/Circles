require "test_helper"

class EventMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @circle_member = create_user
    @circle = create_circle(owner: @host, members: [@circle_member])
    @event = create_event(host: @host, circles: [@circle], private: false)
  end

  test "attendees can post" do
    sign_in @host
    assert_difference "EventMessage.count", 1 do
      post event_event_messages_path(@event), params: { event_message: { content: "hello" } }
    end
    assert_response :success
  end

  test "a circle member who hasn't joined the event cannot post" do
    sign_in @circle_member
    assert_no_difference "EventMessage.count" do
      post event_event_messages_path(@event), params: { event_message: { content: "hi" } }
    end
    assert_redirected_to root_path
  end
end
