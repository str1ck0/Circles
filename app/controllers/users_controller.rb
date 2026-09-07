class UsersController < ApplicationController
  def profile
    skip_authorization
    @events = policy_scope(Event).includes(:user_events, photos_attachments: :blob).order(:start_date)
  end

  def index
    @circle = Circle.find(params[:circle_id])
    authorize @circle, :invite?
    @users = @circle.invitable_users

    if params[:query].present?
      @users = @users.where("first_name ILIKE :q OR last_name ILIKE :q", q: "%#{params[:query]}%")
    end

    respond_to do |format|
      format.html
      format.text { render partial: "circles/users_list", locals: { users: @users, circle: @circle }, formats: [:html] }
    end
  end
end
