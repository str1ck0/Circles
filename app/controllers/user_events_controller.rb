class UserEventsController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    authorize @event, :rsvp?
    @user_event = UserEvent.new(event: @event, user: current_user)

    respond_to do |format|
      if @user_event.save
        format.html { redirect_to @event, notice: "You're in!" }
        format.json { render json: { user_count: @event.users.count } }
      else
        format.html { redirect_to @event, alert: @user_event.errors.full_messages.to_sentence }
        format.json { render json: { errors: @user_event.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
