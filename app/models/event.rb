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

  # Enrol every member of the given circles, skipping anyone already attending.
  def enrol_members_of(circles)
    user_ids = UserCircle.where(circle_id: circles.map(&:id)).distinct.pluck(:user_id)
    user_ids.each { |id| user_events.find_or_create_by!(user_id: id) }
  end
end
