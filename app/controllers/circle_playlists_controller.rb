class CirclePlaylistsController < PlaylistsController
  private

  def find_parent
    Circle.find(params[:circle_id])
  end

  def playlists_for(circle)
    circle.circle_playlists
  end

  def playlist_params
    params.require(:circle_playlist).permit(:url)
  end
end
