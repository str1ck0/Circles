class EventsController < ApplicationController

  def new
    @event = Event.new
    @circles = Circle.all
  end

  def create
    @event = Event.new(event_params)
    @event.user = current_user
    if @event.save
      # Attendees = the creator plus everyone in the circles this event belongs to.
      attendees = ([current_user] + @event.circles.flat_map(&:users)).uniq
      attendees.each { |user| UserEvent.find_or_create_by(event: @event, user: user) }
      redirect_to event_path(@event), notice: "Event created!"
    else
      @circles = Circle.all
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.find(params[:id])
    @event.update(event_params)
    redirect_to event_path(@event)
  end

  def show
    @event = Event.find(params[:id])
    @event_user = current_user
    @user_event = UserEvent.new
    @payment = Payment.new
    @event_message = EventMessage.new
    @circles = @event.circles
    @circle_event = CircleEvent.new
    @event_playlist = EventPlaylist.new
    @marker = Event.where(id: params[:id]).geocoded.map do |event|
      {
        lat: event.latitude,
        lng: event.longitude
        # info_window: render_to_string(partial: "info_window", locals: {event: event})
      }
    end
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :location, :private, :user_id, circle_ids: [], photos: [], images: [])
  end
end
