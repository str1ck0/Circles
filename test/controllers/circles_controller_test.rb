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

  test "circle pages hide unauthorized event cards and memories" do
    [@public_circle, @private_circle].each do |circle|
      event = create_event(host: @owner, circles: [circle], private: true,
                           title: "Secret tournament", location: "Secret venue")
      event.photos.attach(io: File.open(file_fixture("avatar.png")), filename: "secret.png", content_type: "image/png")
      sign_in(circle.private? ? @member : @stranger)
      get circle_path(circle)
      assert_response :success
      assert_select "a[href='#{event_path(event)}']", count: 0
      assert_not_includes response.body, "Secret tournament"
      assert_not_includes response.body, "SECRET TOURNAMENT"
      assert_not_includes response.body, "Secret venue"

      sign_in @owner
      get circle_path(circle)
      assert_response :success
      assert_select "a[href='#{event_path(event)}']", minimum: 1
    end
  end

  test "members still see circle events they are eligible to join" do
    event = create_event(host: @owner, circles: [@private_circle])
    sign_in @member
    get circle_path(@private_circle)
    assert_response :success
    assert_select "a[href='#{event_path(event)}']", minimum: 1
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
