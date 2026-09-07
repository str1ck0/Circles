class UserCircle < ApplicationRecord
  belongs_to :user
  belongs_to :circle
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :user_id, uniqueness: { scope: :circle_id }
end
