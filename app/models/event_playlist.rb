class EventPlaylist < ApplicationRecord
  include SpotifyEmbed

  belongs_to :event
end
