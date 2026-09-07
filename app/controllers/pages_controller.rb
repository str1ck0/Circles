class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  skip_after_action :verify_authorized, only: :home

  def home
    @events = policy_scope(Event).includes(:users, photos_attachments: :blob).order(:start_date)
    if user_signed_in?
      @circles = current_user.circles
      @discover_circles = Circle.publicly_visible.where.not(id: current_user.circle_ids)
    else
      @circles = Circle.publicly_visible
      @discover_circles = Circle.none
    end
    @skip_footer = true
  end
end
