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

  def destroy
    @circle = Circle.find(params[:circle_id])
    membership = @circle.user_circles.find(params[:id])
    leaving = membership.user == current_user
    authorize @circle, leaving ? :leave? : :remove_member?

    return redirect_to @circle, alert: "The owner can't be removed." if membership.user == @circle.owner

    membership.destroy

    if leaving
      # An empty circle is unreachable for everyone, so it goes with the last member.
      name = @circle.name
      emptied = @circle.user_circles.reload.empty?
      @circle.destroy if emptied
      redirect_to root_path, notice: emptied ? "You left #{name}, and it's now empty so we removed it." : "You left #{name}."
    else
      redirect_to @circle, notice: "Removed #{membership.user.first_name} from #{@circle.name}."
    end
  end
end
