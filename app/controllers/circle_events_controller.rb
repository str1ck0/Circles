class CircleEventsController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    authorize @event, :attach_circle?
    circle = Circle.find(params.require(:circle_event).fetch(:circle_id))
    authorize circle, :attach_event?

    @circle_event = CircleEvent.new(circle: circle, event: @event)

    CircleEvent.transaction do
      @circle_event.save!
      @event.enrol_members_of([circle], actor: current_user)
    end
    redirect_to event_path(@event), notice: "#{circle.name} added to the event."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to event_path(@event), alert: e.record.errors.full_messages.to_sentence
  end
end
