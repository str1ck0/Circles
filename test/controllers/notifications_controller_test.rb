require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @me = create_user
    @circle = create_circle(owner: @owner, private: true, name: "Secret Society")
    @event = create_event(host: @owner, circles: [@circle], attendees: [@me], title: "Big Night")
    @notification = Notification.notify(recipient: @me, actor: @owner, notifiable: @event, kind: :event_created)
    @invitation = Invitation.create!(circle: @circle, inviter: @owner, invitee: @me)
    Notification.notify(recipient: @me, actor: @owner, notifiable: @invitation, kind: :circle_invitation)
  end

  test "index lists activity and pending invites, then marks everything read" do
    sign_in @me
    assert_equal 2, @me.notifications.unread.count
    get notifications_path
    assert_response :success
    assert_includes response.body, "invited you to Big Night"
    assert_includes response.body, "invited you to join Secret Society"
    assert_includes response.body, "is-unread"
    assert_equal 0, @me.notifications.unread.count
  end

  test "show marks one read and redirects to its subject" do
    sign_in @me
    get notification_path(@notification)
    assert_redirected_to event_path(@event)
    assert @notification.reload.read?
  end

  test "you can't open someone else's notification" do
    sign_in @owner
    assert_raises(ActiveRecord::RecordNotFound) { get notification_path(@notification) }
    assert_not @notification.reload.read?
  end

  test "the home sidebar shows the unread count" do
    sign_in @me
    get root_path
    assert_includes response.body, 'unread-badge">2<'
  end
end
