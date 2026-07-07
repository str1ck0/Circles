class DashboardController < ApplicationController
  def show
    @user = User.find(params[:id])
    @all_events = Event.all
    @events = @user.events
    @event = @events.first
    @circles = @user.circles
    @circle = @circles.first
    @circle_playlist = CirclePlaylist.new
    # The user's next upcoming event they're attending (guard against having none).
    @next_event = @user.events.where("end_date >= ?", Date.current).order(:start_date).first ||
                  @user.events.order(:start_date).last
  end
end
