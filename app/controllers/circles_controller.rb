class CirclesController < ApplicationController
  def new
    @circle = Circle.new
    @users = current_user.friends
    @user_names = @users.pluck(:first_name)
    @colors = colors
  end

  def create
    @circle = Circle.new(circle_params)
    @circle.owner = current_user
    if @circle.save
      @circle.users << current_user unless @circle.users.include?(current_user)
      redirect_to @circle, notice: 'New Circle created!'
    else
      @users = current_user.friends
      @user_names = @users.pluck(:first_name)
      @colors = colors
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @users = User.all
    @circle = Circle.find(params[:id])
    @circle_events = @circle.circle_events
    @circle_message = CircleMessage.new
    @user_circle = UserCircle.new
    @not_in_group_users = User.where.not(id: @circle.users.select(:id))
    @other_users = @circle.users.where.not(id: current_user.id)
    @circle_playlist = CirclePlaylist.new
  end

  def destroy
    @circle = Circle.find(params[:id])
    if current_user == @circle.owner
      @circle.destroy
      redirect_to root_path, notice: 'Circle deleted.'
    else
      redirect_to @circle, alert: 'Only the circle owner can delete it.'
    end
  end

  private

  def colors
    %w[#33a8c7 #52e3e1 #a0e426 #fdf148 #ffab00 #f77976 #f050ae #d883ff #9336fd #ffbe0b #fb5607 #ff006e #8338ec #3a86ff]
  end

  def circle_params
    params.require(:circle).permit(:name, :photo, :private, :border_color, :banner, user_ids: [])
  end
end
