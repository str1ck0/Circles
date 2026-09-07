class UserEventsController < ApplicationController
  CHOOSABLE_STATUSES = %w[going maybe declined].freeze

  NOTICES = {
    "going" => "You're going!",
    "maybe" => "Marked as maybe.",
    "declined" => "Sorry you can't make it."
  }.freeze

  def create
    @event = Event.find(params[:event_id])
    authorize @event, :rsvp?

    status = params.dig(:user_event, :status).presence || "going"
    return respond_with_error("Unknown RSVP: #{status}") unless CHOOSABLE_STATUSES.include?(status)

    @user_event = @event.user_events.find_or_initialize_by(user: current_user)
    @user_event.status = status

    if @user_event.save
      respond_to do |format|
        format.html { redirect_to @event, notice: NOTICES[status] }
        format.json { render json: { status: status, label: NOTICES[status], counts: @event.rsvp_counts } }
      end
    else
      respond_with_error(@user_event.errors.full_messages.to_sentence)
    end
  end

  private

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to @event, alert: message }
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end
end
