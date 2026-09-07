class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  skip_after_action :verify_authorized, only: :home

  def home
    visible = policy_scope(Event).includes(:user_events, photos_attachments: :blob)
    @events = visible.where("end_date >= ?", Time.current).order(:start_date)
    @past_events = visible.where("end_date < ?", Time.current).order(start_date: :desc).limit(8)

    if user_signed_in?
      @circles = current_user.circles
      @discover_circles = Circle.publicly_visible.where.not(id: current_user.circle_ids).includes(:users, photo_attachment: :blob)
    else
      @circles = Circle.publicly_visible.includes(:users, photo_attachment: :blob)
      @discover_circles = Circle.none
    end
  end
end
