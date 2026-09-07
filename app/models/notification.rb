class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  enum kind: { circle_invitation: 0, invitation_accepted: 1, event_created: 2, rsvp: 3, circle_joined: 4 }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def self.notify(recipient:, notifiable:, kind:, actor: nil)
    return if recipient.nil? || recipient == actor

    create!(recipient: recipient, actor: actor, notifiable: notifiable, kind: kind)
  end

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
