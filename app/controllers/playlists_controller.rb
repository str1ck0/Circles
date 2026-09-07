# Base for adding a Spotify playlist to a circle or an event.
class PlaylistsController < ApplicationController
  def create
    parent = find_parent
    authorize parent, :add_playlist?

    playlist = playlists_for(parent).new(playlist_params)

    if playlist.save
      redirect_to parent, notice: "Playlist added."
    else
      redirect_to parent, alert: playlist.errors.full_messages.to_sentence
    end
  end

  private

  def find_parent
    raise NotImplementedError
  end

  def playlists_for(_parent)
    raise NotImplementedError
  end

  def playlist_params
    raise NotImplementedError
  end
end
