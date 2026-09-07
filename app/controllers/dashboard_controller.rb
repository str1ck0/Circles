class DashboardController < ApplicationController
  def show
    @user = User.find(params[:id])
    authorize @user
    return redirect_to user_path(@user) unless @user == current_user

    @circles = current_user.circles.includes(:users, photo_attachment: :blob).order(:name)

    my_events = current_user.events.includes(:user_events, photos_attachments: :blob)
    @upcoming_events = my_events.where("end_date >= ?", Time.current).order(:start_date).limit(8).to_a
    @next_event = @upcoming_events.first
    @next_rsvp = @next_event&.rsvp_of(current_user)

    @discover_events = policy_scope(Event)
                       .where("end_date >= ?", Time.current)
                       .where.not(id: current_user.event_ids)
                       .includes(:user_events, photos_attachments: :blob)
                       .order(:start_date).limit(8)

    @pending_invitations = current_user.received_invitations.active.includes(:circle, :inviter)
    @friends = current_user.friends.includes(photo_attachment: :blob).order(:first_name).limit(12)
    @playlists = CirclePlaylist.where(circle_id: current_user.circle_ids).includes(:circle).order(created_at: :desc).limit(4)
  end
end
