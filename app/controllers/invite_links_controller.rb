class InviteLinksController < ApplicationController
  before_action :load_open_invitation

  def show
    authorize @invitation, :show?
    @circle = @invitation.circle
    @already_member = @circle.member?(current_user)
  end

  def accept
    authorize @invitation, :redeem?
    @invitation.accept!(current_user)
    redirect_to @invitation.circle, notice: "Welcome to #{@invitation.circle.name}!"
  end

  private

  def load_open_invitation
    @invitation = Invitation.links.find_by!(token: params[:token])
    return if @invitation.pending? && !@invitation.expired?

    skip_authorization
    redirect_to root_path, alert: "This invite link has expired."
  end
end
