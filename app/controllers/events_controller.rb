class EventsController < ApplicationController
  def new
    @event = Event.new
    @event.organising_circle_id = current_user.circles.find(params[:circle_id]).id if params[:circle_id].present?
    authorize @event
  end

  def create
    @event = Event.new(attributes_for_save)
    @event.user = current_user
    circle_id = event_params[:organising_circle_id]
    @event.organising_circle_id = circle_id
    @event.circles = circle_id.present? ? [current_user.circles.find(circle_id)] : []
    @event.private = true if @event.circles.empty?
    authorize @event
    saved = Event.transaction do
      if @event.save
        @event.user_events.create!(user: current_user, status: :going)
        true
      end
    end
    if saved
      redirect_to event_path(@event), notice: "Event created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @event = Event.find(params[:id])
    authorize @event, :update?
  end

  def update
    @event = Event.find(params[:id])
    authorize @event
    attributes = attributes_for_save
    attributes[:private] = true if @event.circles.empty?
    if @event.update(attributes)
      redirect_to event_path(@event), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event = Event.find(params[:id])
    authorize @event
    @event.destroy
    redirect_to root_path, notice: "Event deleted."
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
    @circles = policy_scope(@event.circles)
    @marker = @event.geocoded? ? [{ lat: @event.latitude, lng: @event.longitude }] : []
  end

  private

  # The organising circle is chosen on creation. An empty file field submits a
  # blank string, which would otherwise wipe the existing photos on update.
  def attributes_for_save
    attributes = event_params.except(:organising_circle_id, :images)
    attributes.delete(:photos) if Array(attributes[:photos]).all?(&:blank?)
    attributes
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :location, :private, :organising_circle_id, photos: [], images: [])
  end
end
