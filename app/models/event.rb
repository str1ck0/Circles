class Event < ApplicationRecord
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

  # Invite every member of the given circles, skipping anyone already on the guest list,
  # and let the newly invited know who did it.
  def enrol_members_of(circles, actor: nil)
    user_ids = UserCircle.where(circle_id: circles.map(&:id)).distinct.pluck(:user_id)
    user_ids.each do |id|
      user_event = user_events.find_or_initialize_by(user_id: id)
      next unless user_event.new_record?

      user_event.save!
      Notification.notify(recipient: user_event.user, actor: actor, notifiable: self, kind: :event_created)
    end
  end
end
