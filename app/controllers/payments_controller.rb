class PaymentsController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    authorize @event, :add_payment?

    payer = @event.user_events.find_by(id: payment_params[:user_event_id])
    return redirect_to event_path(@event), alert: "Pick who paid." if payer.nil?

    splittees = @event.user_events.where(id: payment_params[:user_event_ids]).where.not(id: payer.id).to_a
    payment = Payment.new(user_event: payer, description: payment_params[:description], amount: payment_params[:amount])
    payment.user_events = splittees

    Payment.transaction do
      payment.save!
      # Integer split: each splittee owes an equal share and the payer absorbs the
      # remainder, so the balance changes always sum to zero.
      share = payment.amount / (splittees.size + 1)
      payer.update!(balance: payer.balance + share * splittees.size)
      splittees.each { |splittee| splittee.update!(balance: splittee.balance - share) }
    end

    redirect_to event_path(@event), notice: "Added to the Splitty."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to event_path(@event), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def payment_params
    params.require(:payment).permit(:user_event_id, :description, :amount, user_event_ids: [])
  end
end
