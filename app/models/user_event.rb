class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event
  # Both sides of the Splitty point at this row, so they go when the guest does.
  has_many :payments, dependent: :destroy
  has_many :splittees, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum status: { invited: 0, going: 1, maybe: 2, declined: 3 }

  validates :user_id, uniqueness: { scope: :event_id }

  def user_name
    user.first_name
  end
end
