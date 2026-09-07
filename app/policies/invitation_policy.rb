class InvitationPolicy < ApplicationPolicy
  def accept?  = personal_and_usable?
  def decline? = personal_and_usable?

  # Invite links: anyone signed in can see the landing page while the link is open.
  def show?   = user.present? && record.link? && record.usable_by?(user)
  def redeem? = show? && !record.circle.member?(user)

  private

  def personal_and_usable?
    user.present? && !record.link? && record.invitee == user && record.usable_by?(user)
  end
end
