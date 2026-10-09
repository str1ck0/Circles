require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newcomer = create_user
    @veteran = create_user
    @private_circle = create_circle(owner: @veteran, private: true, name: "Secret Society")
  end

  test "a user with no circles gets a dashboard, not a crash" do
    sign_in @newcomer
    get dashboard_path(@newcomer)
    assert_response :success
    assert_includes response.body, "Join a circle to see its playlists."
  end

  test "the owner sees all of their circles and pending invites" do
    Invitation.create!(circle: create_circle(owner: @newcomer, private: true, name: "Book Club"), inviter: @newcomer, invitee: @veteran)
    sign_in @veteran
    get dashboard_path(@veteran)
    assert_response :success
    assert_includes response.body, "Secret Society"
    assert_includes response.body, "invited you to <strong>Book Club</strong>"
  end

  test "unanswered invitations appear separately from plans and declined events are excluded" do
    invited = create_event(host: @veteran, attendees: [@newcomer], title: "Invitation awaiting reply")
    declined = create_event(host: @veteran, attendees: [@newcomer], title: "Declined event")
    declined.rsvp_of(@newcomer).update!(status: :declined)
    sign_in @newcomer
    get dashboard_path(@newcomer)
    assert_response :success
    assert_select ".dash-next", count: 0
    assert_select ".event-invitation", text: /Invitation awaiting reply/
    assert_not_includes response.body, "Declined event"

    invited.rsvp_of(@newcomer).update!(status: :going)
    get dashboard_path(@newcomer)
    assert_select ".dash-next a[href='#{event_path(invited)}']"
    assert_select ".event-invitation", count: 0
  end
end
