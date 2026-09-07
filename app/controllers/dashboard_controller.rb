class DashboardController < ApplicationController
  def show
    @user = User.find(params[:id])
    authorize @user
    @circles = policy_scope(@user.circles)
    @events = policy_scope(@user.events)
    @next_event = @events.where("end_date >= ?", Date.current).order(:start_date).first ||
                  @events.order(:start_date).last
    @circle = @circles.first
    @circle_playlist = CirclePlaylist.new
    @discover_events = policy_scope(Event).includes(photos_attachments: :blob).limit(12)
    @orbit_users = User.where(id: UserCircle.where(circle_id: @circles.select(:id)).select(:user_id))
                       .where.not(id: @user.id).limit(3)
  end
end
