class CirclePlaylistsController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    authorize @circle, :add_playlist?
    @circle_playlist = CirclePlaylist.new(circle_playlist_params)
    @circle_playlist.circle = @circle
    if @circle_playlist.save
      redirect_to @circle, notice: "Playlist added."
    else
      redirect_to @circle, alert: @circle_playlist.errors.full_messages.to_sentence
    end
  end

  private

  def circle_playlist_params
    params.require(:circle_playlist).permit(:url)
  end
end
