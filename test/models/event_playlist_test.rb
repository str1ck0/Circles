require "test_helper"

class EventPlaylistTest < ActiveSupport::TestCase
  # Regression: embed_url used to require a "?" query string and crashed on
  # clean Spotify URLs. It must now extract the playlist ID either way.
  test "embed_url extracts the id from a url with a query string" do
    playlist = EventPlaylist.new(url: "https://open.spotify.com/playlist/1dg4MQuRRxbWkQMb1SnbQX?si=abc123")
    assert_equal "1dg4MQuRRxbWkQMb1SnbQX", playlist.embed_url
  end

  test "embed_url extracts the id from a url without a query string" do
    playlist = EventPlaylist.new(url: "https://open.spotify.com/playlist/1dg4MQuRRxbWkQMb1SnbQX")
    assert_equal "1dg4MQuRRxbWkQMb1SnbQX", playlist.embed_url
  end
end
