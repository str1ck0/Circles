require "test_helper"

class CirclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @member = create_user
    @stranger = create_user
    @private_circle = create_circle(owner: @owner, members: [@member], private: true)
    @public_circle = create_circle(owner: @owner, private: false)
  end

  test "a stranger cannot view a private circle" do
    sign_in @stranger
    get circle_path(@private_circle)
    assert_redirected_to root_path
    assert_equal "You don't have access to that.", flash[:alert]
  end

  test "a member can view a private circle with the chat" do
    sign_in @member
    get circle_path(@private_circle)
    assert_response :success
    assert_includes response.body, "circle-chatroom-subscription"
  end

  test "a stranger can view a public circle but not its chat or add-member controls" do
    sign_in @stranger
    get circle_path(@public_circle)
    assert_response :success
    assert_includes response.body, "Join circle"
    assert_not_includes response.body, "circle-chatroom-subscription"
    assert_not_includes response.body, "Add friends"
  end

  test "only the owner can destroy" do
    sign_in @member
    assert_no_difference "Circle.count" do
      delete circle_path(@private_circle)
    end
    assert_redirected_to root_path

    sign_in @owner
    assert_difference "Circle.count", -1 do
      delete circle_path(@private_circle)
    end
  end

  test "signed-out visitors are sent to log in" do
    get circle_path(@public_circle)
    assert_redirected_to new_user_session_path
  end
end
