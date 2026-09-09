class CirclesController < ApplicationController
  def new
    @circle = Circle.new
    authorize @circle
    @colors = colors
  end

  def create
    @circle = Circle.new(circle_params)
    @circle.owner = current_user
    authorize @circle
    if @circle.save
      @circle.users << current_user unless @circle.users.include?(current_user)
      invited = invite_initial_members
      notice = invited.positive? ? "Circle created — #{helpers.pluralize(invited, 'invite')} sent." : "Circle created!"
      redirect_to @circle, notice: notice
    else
      @colors = colors
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @circle = Circle.find(params[:id])
    authorize @circle
    events = @circle.events.includes(:user_events, photos_attachments: :blob).order(:start_date)
    @upcoming_events = events.select { |event| event.end_date >= Time.current }
    @memory_events = events.select { |event| event.photos.attached? }
    @memberships = @circle.user_circles.joins(:user).includes(user: { photo_attachment: :blob }).order("users.first_name")
    @circle_message = CircleMessage.new
    @circle_playlist = CirclePlaylist.new
    if policy(@circle).invite?
      @invitable_users = @circle.invitable_users
      @invite_link = @circle.invitations.links.active.first
    end
  end

  def destroy
    @circle = Circle.find(params[:id])
    authorize @circle
    @circle.destroy
    redirect_to root_path, notice: "Circle deleted."
  end

  private

  def colors
    %w[#33a8c7 #52e3e1 #a0e426 #fdf148 #ffab00 #f77976 #f050ae #d883ff #9336fd #ffbe0b #fb5607 #ff006e #8338ec #3a86ff]
  end

  # People picked on the form get an invitation to accept, never a silent membership.
  def invite_initial_members
    ids = Array(params.dig(:circle, :invitee_ids)).reject(&:blank?)
    User.where(id: ids).where.not(id: current_user.id).count do |user|
      invitation = @circle.invitations.create(inviter: current_user, invitee: user)
      next false unless invitation.persisted?

      Notification.notify(recipient: user, actor: current_user, notifiable: invitation, kind: :circle_invitation)
      true
    end
  end

  def circle_params
    params.require(:circle).permit(:name, :photo, :private, :border_color, :banner)
  end
end
