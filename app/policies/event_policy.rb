class EventPolicy < ApplicationPolicy
  # Events the viewer may see: ones they're attending, plus public events of circles they
  # belong to. Signed-out visitors only see public events of public circles.
  class Scope < Scope
    def resolve
      if user.nil?
        return scope.where(private: false, id: CircleEvent.joins(:circle).where(circles: { private: false }).select(:event_id))
      end

      attending = UserEvent.where(user_id: user.id).select(:event_id)
      via_circles = CircleEvent.where(circle_id: user.circle_ids).select(:event_id)

      scope.where(id: attending).or(scope.where(private: false, id: via_circles))
    end
  end

  def show?           = attendee? || (record.public? && circle_member?)
  def create?         = user.present?
  def update?         = host?
  def rsvp?           = show? && !attendee?
  def chat?           = attendee?
  def add_playlist?   = attendee?
  def add_payment?    = attendee?
  def attach_circle?  = attendee?

  def attendee?
    user.present? && record.attendee?(user)
  end

  def host?
    user.present? && record.user == user
  end

  private

  def circle_member?
    user.present? && record.circles.where(id: user.circle_ids).exists?
  end
end
