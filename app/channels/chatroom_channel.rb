# Base for the circle and event chat channels: only people the policy lets chat get a stream.
class ChatroomChannel < ApplicationCable::Channel
  def subscribed
    chatroom = self.class.chatroom_class.find_by(id: params[:id])
    return reject unless chatroom && Pundit.policy!(current_user, chatroom).chat?

    stream_for chatroom
  end

  def self.chatroom_class
    raise NotImplementedError, "#{name} must define .chatroom_class"
  end
end
