class CircleMessagesController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    authorize @circle, :chat?
    @circle_message = CircleMessage.new(circle_message_params)
    @circle_message.circle = @circle
    @circle_message.user = current_user
    if @circle_message.save
      CircleChatroomChannel.broadcast_to(
        @circle,
        message: render_to_string(partial: "circle_message", locals: { circle_message: @circle_message }),
        sender_id: @circle_message.user.id
      )
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def circle_message_params
    params.require(:circle_message).permit(:content)
  end
end
