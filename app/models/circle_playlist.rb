class CirclePlaylist < ApplicationRecord
  belongs_to :circle

  # Extract the Spotify playlist ID from a share URL, tolerating URLs with or
  # without a query string (e.g. ".../playlist/ID" or ".../playlist/ID?si=...").
  def embed_url
    url.to_s[%r{playlist/(\w+)}, 1] || url.to_s.split("?").first.split("/").last
  end
end
