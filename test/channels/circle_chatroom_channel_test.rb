require "test_helper"

class CircleChatroomChannelTest < ActionCable::Channel::TestCase
  setup do
    @owner = create_user
    @stranger = create_user
    @circle = create_circle(owner: @owner, private: false)
  end

  test "members stream the circle's chat" do
    stub_connection current_user: @owner
    subscribe id: @circle.id
    assert subscription.confirmed?
    assert_has_stream_for @circle
  end

  test "non-members are rejected, even for a public circle" do
    stub_connection current_user: @stranger
    subscribe id: @circle.id
    assert subscription.rejected?
  end

  test "unknown circles are rejected" do
    stub_connection current_user: @owner
    subscribe id: 0
    assert subscription.rejected?
  end
end
