class CirclePolicy < ApplicationPolicy
  # Circles the viewer may see: every public circle, plus private ones they belong to.
  class Scope < Scope
    def resolve
      return scope.where(private: false) if user.nil?

      scope.where(private: false).or(scope.where(id: user.circle_ids))
    end
  end

  def show?          = record.public? || member?
  def create?        = user.present?
  def destroy?       = owner?
  def join?          = user.present? && record.public? && !member?
  def add_member?    = member?
  def chat?          = member?
  def add_playlist?  = member?
  def create_event?  = member?
  def attach_event?  = member?

  def member?
    user.present? && record.member?(user)
  end

  private

  def owner?
    user.present? && record.owner == user
  end
end
