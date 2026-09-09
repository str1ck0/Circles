class EventsController < ApplicationController
  def new
    @event = Event.new
    authorize @event
  end

  def create
    @event = Event.new(attributes_for_save)
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

  def edit
    @event = Event.find(params[:id])
    authorize @event, :update?
  end

  def update
    @event = Event.find(params[:id])
    authorize @event
    if @event.update(attributes_for_save)
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
    @circle_event = CircleEvent.new
    @circles = policy_scope(@event.circles)
    @attachable_circles = current_user.circles.where.not(id: @event.circle_ids)
    @marker = @event.geocoded? ? [{ lat: @event.latitude, lng: @event.longitude }] : []
  end

  private

  def own_circles(ids)
    current_user.circles.where(id: Array(ids).reject(&:blank?))
  end

  # Circles are managed from the event page, not this form. An empty file field submits a
  # blank string, which would otherwise wipe the existing photos on update.
  def attributes_for_save
    attributes = event_params.except(:circle_ids, :images)
    attributes.delete(:photos) if Array(attributes[:photos]).all?(&:blank?)
    attributes
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :location, :private, circle_ids: [], photos: [], images: [])
  end
end
