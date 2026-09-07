module NotificationsHelper
  def notification_text(notification)
    actor = notification.actor&.full_name || "Someone"
    subject = notification.notifiable

    case notification.kind.to_sym
    when :circle_invitation   then "#{actor} invited you to join #{subject.circle.name}"
    when :invitation_accepted then "#{actor} accepted your invite to #{subject.circle.name}"
    when :event_created       then "#{actor} invited you to #{subject.title}"
    when :rsvp                then "#{actor} is going to #{subject.event.title}"
    when :circle_joined       then "#{actor} joined #{subject.circle.name}"
    end
  end

  def notification_target_path(notification)
    subject = notification.notifiable

    case subject
    when Invitation then notification.circle_invitation? ? notifications_path : circle_path(subject.circle)
    when Event      then event_path(subject)
    when UserEvent  then event_path(subject.event)
    when UserCircle then circle_path(subject.circle)
    else root_path
    end
  end

  def unread_notifications_count
    return 0 unless user_signed_in?

    @unread_notifications_count ||= current_user.notifications.unread.count
  end
end
