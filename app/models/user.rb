class User < ApplicationRecord
  has_many :user_events
  has_many :events, through: :user_events
  has_many :circle_messages
  has_many :event_messages
  has_many :user_circles
  has_many :circles, through: :user_circles
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy, inverse_of: :inviter
  has_many :received_invitations, class_name: "Invitation", foreign_key: :invitee_id, dependent: :destroy, inverse_of: :invitee
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
  has_many :triggered_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify, inverse_of: :actor
  has_one_attached :photo

  validates :first_name, presence: true
  validates :last_name, presence: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  scope :search, lambda { |query|
    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where("first_name ILIKE :q OR last_name ILIKE :q OR username ILIKE :q OR CONCAT(first_name, ' ', last_name) ILIKE :q", q: pattern)
  }

  # Everyone who shares at least one circle with this user (excluding self).
  def friends
    User.where(id: UserCircle.where(circle_id: circle_ids).where.not(user_id: id).select(:user_id))
  end

  def handle
    username.present? ? "@#{username}" : nil
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
