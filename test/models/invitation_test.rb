require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @owner = create_user
    @friend = create_user
    @circle = create_circle(owner: @owner, private: true)
  end

  test "a personal invite is one-shot and makes the invitee a member" do
    invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    assert invitation.usable_by?(@friend)
    assert_not invitation.usable_by?(create_user)

    assert_difference ["UserCircle.count", "Notification.count"], 1 do
      invitation.accept!(@friend)
    end
    assert invitation.accepted?
    assert @circle.member?(@friend)
    assert_not invitation.usable_by?(@friend)
    assert_equal @owner, Notification.last.recipient
  end

  test "a link invite stays open for anyone until it expires" do
    link = Invitation.create!(circle: @circle, inviter: @owner, expires_at: 1.day.from_now)
    assert link.link?
    assert link.usable_by?(@friend)
    assert link.usable_by?(create_user)

    link.accept!(@friend)
    assert link.pending?, "links are reusable"
    assert @circle.member?(@friend)

    link.update!(expires_at: 1.minute.ago)
    assert link.expired?
    assert_not link.usable_by?(create_user)
  end

  test "members and duplicate pending invitees are rejected" do
    assert_not Invitation.new(circle: @circle, inviter: @owner, invitee: @owner).valid?

    Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    duplicate = Invitation.new(circle: @circle, inviter: @owner, invitee: @friend)
    assert_not duplicate.valid?
  end

  test "notifications skip self and vanish with their subject" do
    assert_nil Notification.notify(recipient: @owner, actor: @owner, notifiable: @circle.user_circles.first, kind: :circle_joined)

    invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @friend)
    Notification.notify(recipient: @friend, actor: @owner, notifiable: invitation, kind: :circle_invitation)
    assert_difference "Notification.count", -1 do
      invitation.destroy
    end
  end
end
