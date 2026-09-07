class UsersController < ApplicationController
  # Nested under a circle this is the invite modal's live search; on its own it's the
  # people directory.
  def index
    return invitable_index if params[:circle_id]

    authorize User
    @query = params[:q].to_s.strip
    @users = if @query.present?
               User.search(@query).order(:first_name, :last_name).limit(30)
             else
               current_user.friends.order(:first_name, :last_name).limit(30)
             end
  end

  def show
    @user = User.find(params[:id])
    authorize @user
    @circles = policy_scope(@user.circles)
    @events = policy_scope(@user.events)
              .where("end_date >= ?", Time.current)
              .includes(:user_events, photos_attachments: :blob)
              .order(:start_date)
              .limit(6)
  end

  private

  def invitable_index
    circle = Circle.find(params[:circle_id])
    authorize circle, :invite?
    users = circle.invitable_users
    users = users.merge(User.search(params[:query])) if params[:query].present?
    render partial: "circles/users_list", locals: { users: users, circle: circle }, formats: [:html]
  end
end
