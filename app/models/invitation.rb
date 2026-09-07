class Invitation < ApplicationRecord
  LINK_LIFETIME = 7.days

  belongs_to :circle
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", optional: true
  has_many :notifications, as: :notifiable, dependent: :destroy

  has_secure_token

  enum status: { pending: 0, accepted: 1, declined: 2 }

  scope :links, -> { where(invitee_id: nil) }
  scope :personal, -> { where.not(invitee_id: nil) }
  scope :active, -> { pending.where("expires_at IS NULL OR expires_at > ?", Time.current) }

  validates :invitee_id, uniqueness: { scope: :circle_id, conditions: -> { pending }, message: "already has a pending invite" }, allow_nil: true
  validate :invitee_is_not_a_member, on: :create
  validate :invitee_is_not_the_inviter

  def link?
    invitee_id.nil?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def usable_by?(user)
    return false unless user && pending? && !expired?

    link? || invitee == user
  end

  # Links stay open until they expire; personal invites are one-shot.
  def accept!(user)
    transaction do
      UserCircle.find_or_create_by!(user: user, circle: circle)
      update!(status: :accepted, accepted_at: Time.current) unless link?
      Notification.notify(recipient: inviter, actor: user, notifiable: self, kind: :invitation_accepted)
    end
  end

  def decline!
    update!(status: :declined)
  end

  private

  def invitee_is_not_a_member
    errors.add(:invitee, "is already a member") if invitee && circle&.member?(invitee)
  end

  def invitee_is_not_the_inviter
    errors.add(:invitee, "can't be yourself") if invitee && invitee == inviter
  end
end
