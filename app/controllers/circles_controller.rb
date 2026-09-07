class CirclesController < ApplicationController
  def new
    @circle = Circle.new
    authorize @circle
    @colors = colors
  end

  def create
    @circle = Circle.new(circle_params)
    @circle.owner = current_user
    authorize @circle
    if @circle.save
      @circle.users << current_user unless @circle.users.include?(current_user)
      redirect_to @circle, notice: "New Circle created!"
    else
      @colors = colors
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @circle = Circle.find(params[:id])
    authorize @circle
    events = @circle.events.includes(:user_events, photos_attachments: :blob).order(:start_date)
    @upcoming_events = events.select { |event| event.end_date >= Time.current }
    @memory_events = events.select { |event| event.photos.attached? }
    @members = @circle.users.includes(photo_attachment: :blob).order(:first_name)
    @circle_message = CircleMessage.new
    @circle_playlist = CirclePlaylist.new
    if policy(@circle).invite?
      @invitable_users = @circle.invitable_users
      @invite_link = @circle.invitations.links.active.first
    end
  end

  def destroy
    @circle = Circle.find(params[:id])
    authorize @circle
    @circle.destroy
    redirect_to root_path, notice: "Circle deleted."
  end

  private

  def colors
    %w[#33a8c7 #52e3e1 #a0e426 #fdf148 #ffab00 #f77976 #f050ae #d883ff #9336fd #ffbe0b #fb5607 #ff006e #8338ec #3a86ff]
  end

  def circle_params
    params.require(:circle).permit(:name, :photo, :private, :border_color, :banner, user_ids: [])
  end
end
