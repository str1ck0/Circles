require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @member = create_user
    @friend = create_user
    @stranger = create_user
    @circle = create_circle(owner: @owner, members: [@member], private: true)
  end

  test "a member can invite someone, who gets a notification" do
    sign_in @member
    assert_difference ["Invitation.count", "Notification.count"], 1 do
      post circle_invitations_path(@circle), params: { invitation: { invitee_id: @friend.id } }, as: :json
    end
    assert_response :success
    notification = @friend.notifications.last
    assert notification.circle_invitation?
    assert_equal @member, notification.actor
  end

  test "a non-member cannot invite" do
    sign_in @stranger
    assert_no_difference "Invitation.count" do
      post circle_invitations_path(@circle), params: { invitation: { invitee_id: @friend.id } }, as: :json
    end
    assert_response :forbidden
  end

  test "a member can create an invite link" do
    sign_in @owner
    assert_difference "Invitation.links.count", 1 do
      post circle_invitations_path(@circle)
    end
    assert_redirected_to circle_path(@circle)
    link = Invitation.links.last
    assert_in_delta 7.days.from_now, link.expires_at, 5
  end

  test "the invitee can accept and becomes a member" do
    invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    sign_in @friend
    assert_difference "UserCircle.count", 1 do
      post accept_invitation_path(invitation)
    end
    assert_redirected_to circle_path(@circle)
    assert @circle.member?(@friend)
    assert invitation.reload.accepted?
  end

  test "the invitee can decline" do
    invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    sign_in @friend
    assert_no_difference "UserCircle.count" do
      post decline_invitation_path(invitation)
    end
    assert invitation.reload.declined?
  end

  test "nobody else can accept a personal invite" do
    invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    sign_in @stranger
    assert_no_difference "UserCircle.count" do
      post accept_invitation_path(invitation)
    end
    assert_redirected_to root_path
    assert invitation.reload.pending?
  end

  test "inviting a member is rejected cleanly" do
    sign_in @owner
    post circle_invitations_path(@circle), params: { invitation: { invitee_id: @member.id } }, as: :json
    assert_response :unprocessable_entity
  end
end
