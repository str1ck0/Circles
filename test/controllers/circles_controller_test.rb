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

  test "a member can view a private circle with the chat and invite controls" do
    sign_in @member
    get circle_path(@private_circle)
    assert_response :success
    assert_includes response.body, "CircleChatroomChannel"
    assert_includes response.body, "Invite friends"
    assert_includes response.body, "Create invite link"
  end

  test "a stranger can view a public circle but not its chat or add-member controls" do
    sign_in @stranger
    get circle_path(@public_circle)
    assert_response :success
    assert_includes response.body, "Join circle"
    assert_not_includes response.body, "CircleChatroomChannel"
    assert_not_includes response.body, "Invite friends"
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

  test "the new circle form renders with the invite picker" do
    sign_in @stranger
    get new_circle_path
    assert_response :success
    assert_includes response.body, "Invite people now"
  end

  test "people picked when creating a circle get invites, not memberships" do
    sign_in @stranger
    assert_difference ["Circle.count", "Invitation.count", "Notification.count"], 1 do
      post circles_path, params: { circle: {
        name: "Book Club", private: true, border_color: "#ff9d00",
        photo: fixture_file_upload("avatar.png", "image/png"), banner: fixture_file_upload("avatar.png", "image/png"),
        invitee_ids: [@member.id, @stranger.id]
      } }
    end
    circle = Circle.order(:id).last
    assert_redirected_to circle_path(circle)
    assert_equal [@stranger], circle.users.to_a
    assert_equal @member, circle.invitations.first.invitee
    assert @member.notifications.last.circle_invitation?
  end

  test "signed-out visitors are sent to log in" do
    get circle_path(@public_circle)
    assert_redirected_to new_user_session_path
  end
end
