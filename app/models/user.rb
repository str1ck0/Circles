class User < ApplicationRecord
  has_many :user_events
  has_many :events, through: :user_events
  has_many :circle_messages
  has_many :event_messages
  has_many :user_circles
  has_many :circles, through: :user_circles
  has_one_attached :photo

  validates :first_name, presence: true
  validates :last_name, presence: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Everyone who shares at least one circle with this user (excluding self).
  def friends
    User.where(id: UserCircle.where(circle_id: circle_ids).where.not(user_id: id).select(:user_id))
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
