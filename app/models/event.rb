class Event < ApplicationRecord
  belongs_to :user
  geocoded_by :location
  after_validation :geocode, if: :will_save_change_to_location?

  # reverse_geocoded_by :latitude, :longitude do |obj, geo|
  #   obj.state = geo.state
  #   obj.country_code = geo.country_code
  #   obj.address = [geo.state, geo.country_code].join(",")
  # end
  # after_validation :reverse_geocode

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
end
