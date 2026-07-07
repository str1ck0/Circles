class UserCirclesController < ApplicationController
  def create
    @circle = Circle.find(params[:circle_id])
    @user_circle = UserCircle.new(user_circle_params)
    @user_circle.circle_id = @circle.id

    respond_to do |format|
      if @user_circle.save
        format.html { redirect_to @circle, notice: 'Added friend!' }
        format.json { render json: { user_circle: @user_circle.to_json } }
      else
        format.html { redirect_to @circle, status: :unprocessable_entity }
        format.json { render json: { user_circle: @user_circle.to_json } }
      end
    end
  end

  private

  def user_circle_params
    params.require(:user_circle).permit(:user_id)
  end
end
