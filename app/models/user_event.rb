class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :payments

  validates :user_id, uniqueness: { scope: :event_id }

  def user_name
    user.first_name
  end
end
