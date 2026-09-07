require "test_helper"

class UserCirclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @member = create_user
    @stranger = create_user
    @public_circle = create_circle(owner: @owner, members: [@member], private: false)
    @private_circle = create_circle(owner: @owner, members: [@member], private: true)
  end

  test "anyone can join a public circle, and the owner hears about it" do
    sign_in @stranger
    assert_difference ["UserCircle.count", "Notification.count"], 1 do
      post circle_user_circles_path(@public_circle)
    end
    assert_redirected_to circle_path(@public_circle)
    assert @public_circle.member?(@stranger)
    assert @owner.notifications.last.circle_joined?
  end

  test "nobody can self-join a private circle" do
    sign_in @stranger
    assert_no_difference "UserCircle.count" do
      post circle_user_circles_path(@private_circle)
    end
    assert_redirected_to root_path
    assert_not @private_circle.member?(@stranger)
  end

  test "joining twice is refused" do
    sign_in @member
    assert_no_difference "UserCircle.count" do
      post circle_user_circles_path(@public_circle), as: :json
    end
    assert_response :forbidden
  end

  test "the old add-a-user parameter is ignored" do
    newcomer = create_user
    sign_in @stranger
    post circle_user_circles_path(@public_circle), params: { user_circle: { user_id: newcomer.id } }
    assert @public_circle.member?(@stranger)
    assert_not @public_circle.member?(newcomer)
  end
end
