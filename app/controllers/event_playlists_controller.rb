class EventPlaylistsController < PlaylistsController
  private

  def find_parent
    Event.find(params[:event_id])
  end

  def playlists_for(event)
    event.event_playlists
  end

  def playlist_params
    params.require(:event_playlist).permit(:url)
  end
end
