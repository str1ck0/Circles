require "test_helper"

class CircleMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @stranger = create_user
    @circle = create_circle(owner: @owner, private: false)
  end

  test "members can post" do
    sign_in @owner
    assert_difference "CircleMessage.count", 1 do
      post circle_circle_messages_path(@circle), params: { circle_message: { content: "hello" } }
    end
    assert_response :success
  end

  test "blank messages are rejected without a crash" do
    sign_in @owner
    assert_no_difference "CircleMessage.count" do
      post circle_circle_messages_path(@circle), params: { circle_message: { content: "   " } }
    end
    assert_response :unprocessable_entity
  end

  test "non-members cannot post, even to a public circle" do
    sign_in @stranger
    assert_no_difference "CircleMessage.count" do
      post circle_circle_messages_path(@circle), params: { circle_message: { content: "let me in" } }
    end
    assert_redirected_to root_path
  end
end
