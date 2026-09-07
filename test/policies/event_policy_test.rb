require "test_helper"

class EventPolicyTest < ActiveSupport::TestCase
  setup do
    @host = create_user
    @attendee = create_user
    @circle_member = create_user
    @stranger = create_user
    @circle = create_circle(owner: @host, members: [@circle_member], private: true)
    @public_event = create_event(host: @host, circles: [@circle], attendees: [@attendee], private: false)
    @private_event = create_event(host: @host, circles: [@circle], attendees: [@attendee], private: true)
  end

  test "attendees can see any event they're on" do
    assert EventPolicy.new(@attendee, @public_event).show?
    assert EventPolicy.new(@attendee, @private_event).show?
  end

  test "circle members can see the circle's public events but not its private ones" do
    assert EventPolicy.new(@circle_member, @public_event).show?
    assert_not EventPolicy.new(@circle_member, @private_event).show?
  end

  test "strangers see nothing" do
    assert_not EventPolicy.new(@stranger, @public_event).show?
    assert_not EventPolicy.new(@stranger, @private_event).show?
    assert_not EventPolicy.new(nil, @public_event).show?
  end

  test "anyone who can see an event can RSVP, including changing an existing answer" do
    assert EventPolicy.new(@circle_member, @public_event).rsvp?
    assert EventPolicy.new(@attendee, @public_event).rsvp?
    assert EventPolicy.new(@attendee, @private_event).rsvp?
    assert_not EventPolicy.new(@stranger, @public_event).rsvp?
    assert_not EventPolicy.new(@circle_member, @private_event).rsvp?
  end

  test "chat, playlists, payments and attaching circles are attendees only" do
    %i[chat? add_playlist? add_payment? attach_circle?].each do |action|
      assert EventPolicy.new(@attendee, @public_event).public_send(action), action
      assert_not EventPolicy.new(@circle_member, @public_event).public_send(action), action
    end
  end

  test "only the host can update" do
    assert EventPolicy.new(@host, @public_event).update?
    assert_not EventPolicy.new(@attendee, @public_event).update?
  end

  test "scope matches show? for each viewer" do
    unrelated = create_event(host: @stranger)

    assert_equal [@public_event, @private_event].sort_by(&:id),
                 EventPolicy::Scope.new(@attendee, Event.all).resolve.sort_by(&:id)
    assert_equal [@public_event], EventPolicy::Scope.new(@circle_member, Event.all).resolve.to_a
    assert_equal [unrelated], EventPolicy::Scope.new(@stranger, Event.all).resolve.to_a
  end

  test "signed-out scope only includes public events of public circles" do
    public_circle = create_circle(owner: @host, private: false)
    open_event = create_event(host: @host, circles: [public_circle], private: false)
    hidden_event = create_event(host: @host, circles: [public_circle], private: true)

    visible = EventPolicy::Scope.new(nil, Event.all).resolve
    assert_includes visible, open_event
    assert_not_includes visible, hidden_event
    assert_not_includes visible, @public_event
  end
end
