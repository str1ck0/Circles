class EventInvitationsController < ApplicationController
  before_action :load_event

  def new
    @query = params[:q].to_s.strip
    candidates = User.where.not(id: @event.user_events.select(:user_id))
    @users = if @query.present?
               candidates.search(@query)
             else
               candidates.where(id: current_user.friends.select(:id))
             end.order(:first_name, :last_name, :id).includes(photo_attachment: :blob).limit(20)
  end

  def create
    invitee = User.find(params.require(:event_invitation).fetch(:user_id))
    @event.invite!(invitee, actor: current_user)
    redirect_to new_event_event_invitation_path(@event), notice: "#{invitee.first_name} is on the guest list.", status: :see_other
  end

  private

  def load_event
    @event = Event.find(params[:event_id])
    authorize @event, :invite?
  end
end
