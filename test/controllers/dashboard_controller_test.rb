require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newcomer = create_user
    @veteran = create_user
    @private_circle = create_circle(owner: @veteran, private: true, name: "Secret Society")
    @public_circle = create_circle(owner: @veteran, private: false, name: "Public Club")
  end

  test "a user with no circles gets a dashboard, not a crash" do
    sign_in @newcomer
    get dashboard_path(@newcomer)
    assert_response :success
    assert_includes response.body, "Join a circle to see its playlists."
  end

  test "viewing someone else only reveals circles you may see" do
    sign_in @newcomer
    get dashboard_path(@veteran)
    assert_response :success
    assert_includes response.body, "Public Club"
    assert_not_includes response.body, "Secret Society"
  end

  test "the owner sees all of their circles" do
    sign_in @veteran
    get dashboard_path(@veteran)
    assert_response :success
    assert_includes response.body, "Secret Society"
  end
end
