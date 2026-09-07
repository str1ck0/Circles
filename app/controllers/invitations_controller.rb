class InvitationsController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    authorize @circle, :invite?

    invitee_id = params.dig(:invitation, :invitee_id)
    invitation = if invitee_id.present?
                   @circle.invitations.new(inviter: current_user, invitee: User.find(invitee_id))
                 else
                   @circle.invitations.new(inviter: current_user, expires_at: Invitation::LINK_LIFETIME.from_now)
                 end

    respond_to do |format|
      if invitation.save
        Notification.notify(recipient: invitation.invitee, actor: current_user, notifiable: invitation, kind: :circle_invitation)
        notice = invitation.link? ? "Invite link created — it works for 7 days." : "Invited #{invitation.invitee.first_name}."
        format.html { redirect_to @circle, notice: notice }
        format.json { render json: { invitation: invitation.slice(:id, :status) } }
      else
        format.html { redirect_to @circle, alert: invitation.errors.full_messages.to_sentence }
        format.json { render json: { errors: invitation.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def accept
    invitation = Invitation.find(params[:id])
    authorize invitation
    invitation.accept!(current_user)
    redirect_to invitation.circle, notice: "Welcome to #{invitation.circle.name}!"
  end

  def decline
    invitation = Invitation.find(params[:id])
    authorize invitation
    invitation.decline!
    redirect_back fallback_location: notifications_path, notice: "Invite declined."
  end
end
