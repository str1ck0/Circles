require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user
    @visitor = create_user
    @public_circle = create_circle(owner: @owner, private: false, name: "Public Club")
    @private_circle = create_circle(owner: @owner, private: true, name: "Secret Society")
    @public_event = create_event(host: @owner, circles: [@public_circle], private: false, title: "Open Mic")
    @private_event = create_event(host: @owner, circles: [@private_circle], private: true, title: "Hidden Dinner")
  end

  test "signed-out visitors see public circles and their public events only" do
    get root_path
    assert_response :success
    assert_includes response.body, "Public Club"
    assert_includes response.body, "OPEN MIC"
    assert_not_includes response.body, "Secret Society"
    assert_not_includes response.body, "HIDDEN DINNER"
  end

  test "a new user sees only their circles' events, with public circles under Discover" do
    sign_in @visitor
    get root_path
    assert_response :success
    assert_includes response.body, "DISCOVER"
    assert_includes response.body, "Public Club"
    assert_not_includes response.body, "Secret Society"
    assert_not_includes response.body, "OPEN MIC"
    assert_not_includes response.body, "HIDDEN DINNER"
  end

  test "a member sees their private circle's events" do
    sign_in @owner
    get root_path
    assert_response :success
    assert_includes response.body, "HIDDEN DINNER"
    assert_includes response.body, "OPEN MIC"
  end
end
