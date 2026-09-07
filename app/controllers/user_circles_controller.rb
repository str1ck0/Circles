class UserCirclesController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    authorize @circle, :join?
    @user_circle = UserCircle.new(user: current_user, circle: @circle)

    respond_to do |format|
      if @user_circle.save
        Notification.notify(recipient: @circle.owner, actor: current_user, notifiable: @user_circle, kind: :circle_joined)
        format.html { redirect_to @circle, notice: "You joined #{@circle.name}!" }
        format.json { render json: { user_circle: @user_circle } }
      else
        format.html { redirect_to @circle, alert: @user_circle.errors.full_messages.to_sentence }
        format.json { render json: { errors: @user_circle.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
