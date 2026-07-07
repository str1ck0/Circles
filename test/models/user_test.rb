require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(attrs = {})
    User.new({
      email: "user#{rand(1_000_000)}@example.com",
      password: "password",
      first_name: "Sam",
      last_name: "Smith"
    }.merge(attrs))
  end

  test "full_name joins first and last name" do
    assert_equal "Sam Smith", build_user.full_name
  end

  test "requires a first and last name" do
    assert_not build_user(first_name: "").valid?
    assert_not build_user(last_name: "").valid?
  end

  # Regression: first/last name used to be validated as unique, which wrongly
  # stopped two people from sharing a surname.
  test "two users can share a last name" do
    build_user(last_name: "Jones").save!
    second = build_user(last_name: "Jones")
    assert second.valid?, second.errors.full_messages.join(", ")
  end

  test "friends returns members of shared circles, excluding self" do
    me = build_user
    friend = build_user
    stranger = build_user
    [me, friend, stranger].each(&:save!)

    circle = Circle.new(name: "Test", border_color: "#fff")
    circle.save!(validate: false) # skip the photo/banner presence validations
    UserCircle.create!(user: me, circle: circle)
    UserCircle.create!(user: friend, circle: circle)

    assert_includes me.friends, friend
    assert_not_includes me.friends, me
    assert_not_includes me.friends, stranger
  end
end
