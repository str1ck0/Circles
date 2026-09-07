require "test_helper"

class UserCirclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @member = create_user
    @stranger = create_user
    @newcomer = create_user
    @public_circle = create_circle(owner: @owner, members: [@member], private: false)
    @private_circle = create_circle(owner: @owner, members: [@member], private: true)
  end

  test "anyone can join a public circle" do
    sign_in @stranger
    assert_difference "UserCircle.count", 1 do
      post circle_user_circles_path(@public_circle)
    end
    assert_redirected_to circle_path(@public_circle)
    assert @public_circle.member?(@stranger)
  end

  test "nobody can self-join a private circle" do
    sign_in @stranger
    assert_no_difference "UserCircle.count" do
      post circle_user_circles_path(@private_circle)
    end
    assert_redirected_to root_path
    assert_not @private_circle.member?(@stranger)
  end

  test "a member can add someone to a private circle" do
    sign_in @member
    assert_difference "UserCircle.count", 1 do
      post circle_user_circles_path(@private_circle), params: { user_circle: { user_id: @newcomer.id } }, as: :json
    end
    assert_response :success
    assert @private_circle.member?(@newcomer)
  end

  test "a non-member cannot add anyone to a circle" do
    sign_in @stranger
    assert_no_difference "UserCircle.count" do
      post circle_user_circles_path(@private_circle), params: { user_circle: { user_id: @newcomer.id } }, as: :json
    end
    assert_response :forbidden
  end

  test "joining twice is rejected cleanly" do
    sign_in @member
    assert_no_difference "UserCircle.count" do
      post circle_user_circles_path(@public_circle), params: { user_circle: { user_id: @member.id } }, as: :json
    end
    assert_response :forbidden
  end
end
