require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @me = create_user(first_name: "Ada", last_name: "Lovelace", username: "ada")
    @friend = create_user(first_name: "Grace", last_name: "Hopper", username: "amazinggrace", bio: "Compilers.")
    @stranger = create_user(first_name: "Linus", last_name: "Torvalds", username: "torvalds")
    @shared_circle = create_circle(owner: @friend, members: [@me], private: true, name: "Shared Secret")
    @hidden_circle = create_circle(owner: @friend, private: true, name: "Hidden Society")
    @public_circle = create_circle(owner: @friend, private: false, name: "Public Club")
  end

  test "a profile shows bio and only the circles the viewer may see" do
    sign_in @me
    get user_path(@friend)
    assert_response :success
    assert_includes response.body, "Grace Hopper"
    assert_includes response.body, "@amazinggrace"
    assert_includes response.body, "Compilers."
    assert_includes response.body, "Shared Secret"
    assert_includes response.body, "Public Club"
    assert_not_includes response.body, "Hidden Society"
    assert_not_includes response.body, "Edit profile"
  end

  test "your own profile offers edit and dashboard links" do
    sign_in @me
    get user_path(@me)
    assert_response :success
    assert_includes response.body, "Edit profile"
    assert_includes response.body, "YOUR CIRCLES"
  end

  test "the people page defaults to your circle-mates and searches everyone" do
    sign_in @me
    get users_path
    assert_response :success
    assert_includes response.body, "Grace Hopper"
    assert_not_includes response.body, "Linus Torvalds"

    get users_path(q: "torv")
    assert_includes response.body, "Linus Torvalds"
    assert_not_includes response.body, "Grace Hopper"

    get users_path(q: "grace hop")
    assert_includes response.body, "Grace Hopper"
  end

  test "someone else's dashboard redirects to their profile" do
    sign_in @me
    get dashboard_path(@friend)
    assert_redirected_to user_path(@friend)
  end

  test "signed-out visitors are sent to log in" do
    get user_path(@friend)
    assert_redirected_to new_user_session_path
  end

  test "you can update your bio and username" do
    sign_in @me
    patch user_registration_path, params: { user: { bio: "Analytical engines.", username: "countess", current_password: "password" } }
    assert_redirected_to root_path
    assert_equal "Analytical engines.", @me.reload.bio
    assert_equal "countess", @me.username
  end
end
