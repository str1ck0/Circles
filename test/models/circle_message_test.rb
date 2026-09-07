require "test_helper"

class CircleMessageTest < ActiveSupport::TestCase
  setup do
    @owner = create_user
    @circle = create_circle(owner: @owner)
  end

  test "requires content" do
    assert_not CircleMessage.new(circle: @circle, user: @owner, content: "").valid?
    assert CircleMessage.new(circle: @circle, user: @owner, content: "hi").valid?
  end

  test "knows its sender" do
    message = CircleMessage.create!(circle: @circle, user: @owner, content: "hi")
    assert message.sender?(@owner)
    assert_not message.sender?(create_user)
    assert_not message.sender?(nil)
  end

  test "playlists must be Spotify links and expose an embed id" do
    playlist = CirclePlaylist.new(circle: @circle, url: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc")
    assert playlist.valid?
    assert_equal "37i9dQZF1DXcBWIGoYBM5M", playlist.embed_url
    assert_not CirclePlaylist.new(circle: @circle, url: "https://example.com/nope").valid?
  end
end
