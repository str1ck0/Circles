class UserCirclesController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    user = target_user
    authorize @circle, user == current_user ? :join? : :add_member?

    @user_circle = UserCircle.new(user: user, circle: @circle)

    respond_to do |format|
      if @user_circle.save
        notice = user == current_user ? "You joined #{@circle.name}!" : "Added #{user.first_name} to #{@circle.name}."
        format.html { redirect_to @circle, notice: notice }
        format.json { render json: { user_circle: @user_circle } }
      else
        format.html { redirect_to @circle, alert: @user_circle.errors.full_messages.to_sentence }
        format.json { render json: { errors: @user_circle.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def target_user
    user_id = params.dig(:user_circle, :user_id)
    user_id.present? ? User.find(user_id) : current_user
  end
end
