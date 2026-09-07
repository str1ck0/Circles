class EventMessagesController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    authorize @event, :chat?
    @event_message = EventMessage.new(event_message_params)
    @event_message.event = @event
    @event_message.user = current_user
    if @event_message.save
      EventChatroomChannel.broadcast_to(
        @event,
        message: render_to_string(partial: "event_message", locals: { event_message: @event_message }),
        sender_id: @event_message.user.id
      )
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def event_message_params
    params.require(:event_message).permit(:content)
  end
end
