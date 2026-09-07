require "test_helper"

class CirclePolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create_user
    @member = create_user
    @stranger = create_user
    @public_circle = create_circle(owner: @owner, members: [@member], private: false)
    @private_circle = create_circle(owner: @owner, members: [@member], private: true)
  end

  test "public circles are visible to everyone, private ones only to members" do
    assert CirclePolicy.new(@stranger, @public_circle).show?
    assert CirclePolicy.new(nil, @public_circle).show?
    assert CirclePolicy.new(@member, @private_circle).show?
    assert_not CirclePolicy.new(@stranger, @private_circle).show?
    assert_not CirclePolicy.new(nil, @private_circle).show?
  end

  test "only non-members can join, and only public circles" do
    assert CirclePolicy.new(@stranger, @public_circle).join?
    assert_not CirclePolicy.new(@member, @public_circle).join?
    assert_not CirclePolicy.new(@stranger, @private_circle).join?
  end

  test "chat, playlists, inviting and attaching events are members only" do
    %i[chat? add_playlist? invite? attach_event? create_event?].each do |action|
      assert CirclePolicy.new(@member, @public_circle).public_send(action), action
      assert_not CirclePolicy.new(@stranger, @public_circle).public_send(action), action
    end
  end

  test "only the owner can destroy" do
    assert CirclePolicy.new(@owner, @private_circle).destroy?
    assert_not CirclePolicy.new(@member, @private_circle).destroy?
  end

  test "scope returns public circles plus the user's private ones" do
    other_private = create_circle(owner: @stranger, private: true)

    visible = CirclePolicy::Scope.new(@member, Circle.all).resolve
    assert_includes visible, @public_circle
    assert_includes visible, @private_circle
    assert_not_includes visible, other_private

    assert_equal [@public_circle], CirclePolicy::Scope.new(nil, Circle.all).resolve.to_a
  end
end
