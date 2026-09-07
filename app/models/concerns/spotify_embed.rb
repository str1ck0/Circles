# Shared by CirclePlaylist and EventPlaylist: turn a Spotify share URL into an embed id.
module SpotifyEmbed
  extend ActiveSupport::Concern

  included do
    validates :url, presence: true, format: { with: %r{\Ahttps://open\.spotify\.com/}, message: "must be a Spotify link" }
  end

  # Tolerates URLs with or without a query string (".../playlist/ID" or ".../playlist/ID?si=...").
  def embed_url
    url.to_s[%r{playlist/(\w+)}, 1] || url.to_s.split("?").first.split("/").last
  end
end
