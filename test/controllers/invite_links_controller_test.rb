require "test_helper"

class InviteLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @newcomer = create_user
    @circle = create_circle(owner: @owner, private: true, name: "Secret Society")
    @link = Invitation.create!(circle: @circle, inviter: @owner, expires_at: 7.days.from_now)
  end

  test "a signed-in visitor sees the circle and can join" do
    sign_in @newcomer
    get invite_link_path(@link.token)
    assert_response :success
    assert_includes response.body, "Secret Society"
    assert_includes response.body, "Join Secret Society"

    assert_difference "UserCircle.count", 1 do
      post accept_invite_link_path(@link.token)
    end
    assert_redirected_to circle_path(@circle)
    assert @circle.member?(@newcomer)
    assert @link.reload.pending?, "link is still usable by the next person"
  end

  test "an existing member is told so instead of joining twice" do
    sign_in @owner
    get invite_link_path(@link.token)
    assert_response :success
    assert_includes response.body, "already a member"
    assert_no_difference "UserCircle.count" do
      post accept_invite_link_path(@link.token)
    end
  end

  test "expired links are refused" do
    @link.update!(expires_at: 1.minute.ago)
    sign_in @newcomer
    get invite_link_path(@link.token)
    assert_redirected_to root_path
    assert_equal "This invite link has expired.", flash[:alert]
    assert_no_difference "UserCircle.count" do
      post accept_invite_link_path(@link.token)
    end
  end

  test "signed-out visitors are sent to log in first" do
    get invite_link_path(@link.token)
    assert_redirected_to new_user_session_path
  end
end
