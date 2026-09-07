class EventMessagesController < ChatMessagesController
  private

  def find_chatroom
    Event.find(params[:event_id])
  end

  def messages_for(event)
    event.event_messages
  end

  def channel_class
    EventChatroomChannel
  end

  def message_params
    params.require(:event_message).permit(:content)
  end
end
