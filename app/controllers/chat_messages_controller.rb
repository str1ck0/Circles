# Base for posting into a circle or event chat. Subclasses say which chatroom, which
# messages association, which channel to broadcast on and which param key to read.
class ChatMessagesController < ApplicationController
  def create
    chatroom = find_chatroom
    authorize chatroom, :chat?

    message = messages_for(chatroom).new(message_params.merge(user: current_user))

    if message.save
      channel_class.broadcast_to(
        chatroom,
        message: render_to_string(partial: "shared/chat_message", locals: { message: message }),
        sender_id: current_user.id
      )
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def find_chatroom
    raise NotImplementedError
  end

  def messages_for(_chatroom)
    raise NotImplementedError
  end

  def channel_class
    raise NotImplementedError
  end

  def message_params
    raise NotImplementedError
  end
end
