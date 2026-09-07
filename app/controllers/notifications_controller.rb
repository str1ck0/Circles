class NotificationsController < ApplicationController
  # Everything here is scoped to current_user's own notifications.
  after_action :skip_authorization

  def index
    @pending_invitations = current_user.received_invitations.active.includes(:circle, :inviter)
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable).limit(50).to_a
    current_user.notifications.unread.update_all(read_at: Time.current)
  end

  def show
    notification = current_user.notifications.find(params[:id])
    notification.mark_read!
    redirect_to helpers.notification_target_path(notification)
  end
end
