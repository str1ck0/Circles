class CircleChatroomChannel < ApplicationCable::Channel
  def subscribed
    circle = Circle.find_by(id: params[:id])
    return reject unless circle && CirclePolicy.new(current_user, circle).chat?

    stream_for circle
  end
end
