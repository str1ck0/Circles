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
end
