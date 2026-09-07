class CircleMessagesController < ChatMessagesController
  private

  def find_chatroom
    Circle.find(params[:circle_id])
  end

  def messages_for(circle)
    circle.circle_messages
  end

  def channel_class
    CircleChatroomChannel
  end

  def message_params
    params.require(:circle_message).permit(:content)
  end
end
