class Circle < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :circle_events, dependent: :destroy
  has_many :events, through: :circle_events
  has_many :user_circles, dependent: :destroy
  has_many :users, through: :user_circles
  has_many :circle_messages, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_one_attached :photo
  has_one_attached :banner
  has_many :circle_playlists, dependent: :destroy

  # Form-only: people picked on the "new circle" form, turned into invitations by the controller.
  attr_accessor :invitee_ids

  validates :name, presence: true
  validates :photo, presence: true
  validates :banner, presence: true
  validates :border_color, presence: true

  scope :publicly_visible, -> { where(private: false) }

  def public?
    !private?
  end

  def member?(user)
    user.present? && user_circles.exists?(user_id: user.id)
  end

  # People who could still be invited: not members, no open personal invite.
  def invitable_users
    User.where.not(id: user_circles.select(:user_id))
        .where.not(id: invitations.active.personal.select(:invitee_id))
  end
end
