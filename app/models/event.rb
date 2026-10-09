class Event < ApplicationRecord
  attr_accessor :organising_circle_id

  belongs_to :user
  geocoded_by :location
  after_validation :geocode, if: :will_save_change_to_location?

  has_many :user_events, dependent: :destroy
  has_many :users, through: :user_events
  has_many :circle_events, dependent: :destroy
  has_many :circles, through: :circle_events
  has_many :event_messages, dependent: :destroy
  has_many_attached :photos
  has_many_attached :images
  has_many :event_playlists, dependent: :destroy
  has_many :payments, through: :user_events
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :title, presence: true
  validates :location, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  def public?
    !private?
  end

  def attendee?(user)
    user.present? && user_events.exists?(user_id: user.id)
  end

  def rsvp_of(user)
    user_events.find_by(user_id: user.id) if user
  end

  def going_count
    user_events.select(&:going?).size
  end

  def rsvp_counts
    UserEvent.statuses.keys.index_with { 0 }.merge(user_events.group(:status).count)
  end

  # A guest invitation grants access to this event, never to its organising circle.
  # Serialize host invitations so retries do not reset an RSVP or send duplicate notices.
  def invite!(invitee, actor:)
    with_lock do
      guest = user_events.find_by(user: invitee)
      return guest if guest

      guest = user_events.create!(user: invitee, status: :invited)
      Notification.notify(recipient: invitee, actor: actor, notifiable: guest, kind: :event_invitation)
      guest
    end
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after the start time") if end_date <= start_date
  end
end
