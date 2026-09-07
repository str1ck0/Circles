class EventChatroomChannel < ApplicationCable::Channel
  def subscribed
    event = Event.find_by(id: params[:id])
    return reject unless event && EventPolicy.new(current_user, event).chat?

    stream_for event
  end
end
