class EventPlaylistsController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    authorize @event, :add_playlist?
    @event_playlist = EventPlaylist.new(event_playlist_params)
    @event_playlist.event = @event
    if @event_playlist.save
      redirect_to @event, notice: "Playlist added."
    else
      redirect_to @event, alert: @event_playlist.errors.full_messages.to_sentence
    end
  end

  private

  def event_playlist_params
    params.require(:event_playlist).permit(:url)
  end
end
