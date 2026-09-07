class CirclePlaylist < ApplicationRecord
  include SpotifyEmbed

  belongs_to :circle
end
