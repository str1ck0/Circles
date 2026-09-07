class DashboardController < ApplicationController
  def show
    @user = User.find(params[:id])
    authorize @user
    return redirect_to user_path(@user) unless @user == current_user

    @circles = current_user.circles
    @events = current_user.events
    @next_event = @events.where("end_date >= ?", Date.current).order(:start_date).first ||
                  @events.order(:start_date).last
    @circle = @circles.first
    @circle_playlist = CirclePlaylist.new
    @discover_events = policy_scope(Event).includes(photos_attachments: :blob).limit(12)
    @pending_invitations = current_user.received_invitations.active.includes(:circle, :inviter)
    @orbit_users = current_user.friends.limit(3)
  end
end
