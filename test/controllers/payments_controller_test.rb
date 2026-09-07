require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = create_user
    @a = create_user
    @b = create_user
    @stranger = create_user
    @event = create_event(host: @host, attendees: [@a, @b])
    @payer = @event.user_events.find_by(user: @host)
    @ue_a = @event.user_events.find_by(user: @a)
    @ue_b = @event.user_events.find_by(user: @b)
  end

  test "splits with the payer absorbing the remainder so balances net to zero" do
    sign_in @host
    assert_difference "Payment.count", 1 do
      post event_payments_path(@event), params: { payment: {
        amount: 10, description: "Pizza", user_event_id: @payer.id, user_event_ids: [@ue_a.id, @ue_b.id]
      } }
    end
    assert_redirected_to event_path(@event)
    assert_equal 6, @payer.reload.balance
    assert_equal(-3, @ue_a.reload.balance)
    assert_equal(-3, @ue_b.reload.balance)
    assert_equal 0, @event.user_events.sum(:balance)
  end

  test "an invalid payment changes nothing" do
    sign_in @host
    assert_no_difference "Payment.count" do
      post event_payments_path(@event), params: { payment: {
        amount: 0, description: "", user_event_id: @payer.id, user_event_ids: [@ue_a.id]
      } }
    end
    assert_redirected_to event_path(@event)
    assert_equal 0, @payer.reload.balance
    assert_equal 0, @ue_a.reload.balance
  end

  test "splittees from other events are ignored" do
    other_event = create_event(host: @stranger)
    outsider = other_event.user_events.first

    sign_in @host
    post event_payments_path(@event), params: { payment: {
      amount: 9, description: "Cab", user_event_id: @payer.id, user_event_ids: [@ue_a.id, outsider.id]
    } }
    assert_equal 4, @payer.reload.balance
    assert_equal(-4, @ue_a.reload.balance)
    assert_equal 0, outsider.reload.balance
  end

  test "non-attendees cannot add payments" do
    sign_in @stranger
    assert_no_difference "Payment.count" do
      post event_payments_path(@event), params: { payment: {
        amount: 10, description: "Nope", user_event_id: @payer.id, user_event_ids: [@ue_a.id]
      } }
    end
    assert_redirected_to root_path
  end
end
