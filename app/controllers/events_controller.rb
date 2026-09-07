class EventsController < ApplicationController
  def new
    @event = Event.new
    authorize @event
  end

  def create
    @event = Event.new(event_params.except(:circle_ids))
    @event.user = current_user
    @event.circles = own_circles(event_params[:circle_ids])
    authorize @event
    if @event.save
      @event.user_events.create!(user: current_user, status: :going)
      @event.enrol_members_of(@event.circles, actor: current_user)
      redirect_to event_path(@event), notice: "Event created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.find(params[:id])
    authorize @event
    if @event.update(event_params.except(:circle_ids))
      redirect_to event_path(@event), notice: "Event updated."
    else
      redirect_to event_path(@event), alert: @event.errors.full_messages.to_sentence
    end
  end

  def show
    @event = Event.find(params[:id])
    authorize @event
    @user_event = @event.rsvp_of(current_user)
    @rsvp_counts = @event.rsvp_counts
    @guest_list = @event.user_events.includes(:user).group_by(&:status)
    @going_user_events = @event.user_events.going.includes(:user)
    @payment = Payment.new
    @event_message = EventMessage.new
    @event_playlist = EventPlaylist.new
    @circle_event = CircleEvent.new
    @circles = policy_scope(@event.circles)
    @attachable_circles = current_user.circles.where.not(id: @event.circle_ids)
    @marker = @event.geocoded? ? [{ lat: @event.latitude, lng: @event.longitude }] : []
  end

  private

  def own_circles(ids)
    current_user.circles.where(id: Array(ids).reject(&:blank?))
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :location, :private, circle_ids: [], photos: [], images: [])
  end
end
