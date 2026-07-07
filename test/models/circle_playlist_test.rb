require "test_helper"

class CirclePlaylistTest < ActiveSupport::TestCase
  # Regression: embed_url used to require a "?" query string and crashed on
  # clean Spotify URLs. It must now extract the playlist ID either way.
  test "embed_url extracts the id from a url with a query string" do
    playlist = CirclePlaylist.new(url: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc123")
    assert_equal "37i9dQZF1DXcBWIGoYBM5M", playlist.embed_url
  end

  test "embed_url extracts the id from a url without a query string" do
    playlist = CirclePlaylist.new(url: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
    assert_equal "37i9dQZF1DXcBWIGoYBM5M", playlist.embed_url
  end
end
