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

  test "a member can leave a circle they don't own" do
    membership = @private_circle.user_circles.find_by(user: @member)
    sign_in @member
    assert_difference "UserCircle.count", -1 do
      delete circle_user_circle_path(@private_circle, membership)
    end
    assert_redirected_to root_path
    assert_not @private_circle.reload.member?(@member)
  end

  test "the owner cannot leave, only delete" do
    membership = @private_circle.user_circles.find_by(user: @owner)
    sign_in @owner
    assert_no_difference "UserCircle.count" do
      delete circle_user_circle_path(@private_circle, membership)
    end
    assert_redirected_to root_path
    assert @private_circle.reload.member?(@owner)
  end

  test "the owner can remove another member" do
    membership = @private_circle.user_circles.find_by(user: @member)
    sign_in @owner
    assert_difference "UserCircle.count", -1 do
      delete circle_user_circle_path(@private_circle, membership)
    end
    assert_redirected_to circle_path(@private_circle)
    assert_not @private_circle.reload.member?(@member)
  end

  test "a plain member cannot remove someone else" do
    owners_membership = @private_circle.user_circles.find_by(user: @owner)
    sign_in @member
    assert_no_difference "UserCircle.count" do
      delete circle_user_circle_path(@private_circle, owners_membership)
    end
    assert_redirected_to root_path
  end

  test "the last member leaving takes the empty circle with them" do
    circle = create_circle(owner: @owner, private: true)
    circle.update!(owner: nil)
    membership = circle.user_circles.find_by(user: @owner)
    sign_in @owner
    assert_difference "Circle.count", -1 do
      delete circle_user_circle_path(circle, membership)
    end
    assert_redirected_to root_path
  end

  test "the old add-a-user parameter is ignored" do
    newcomer = create_user
    sign_in @stranger
    post circle_user_circles_path(@public_circle), params: { user_circle: { user_id: newcomer.id } }
    assert @public_circle.member?(@stranger)
    assert_not @public_circle.member?(newcomer)
  end
end
