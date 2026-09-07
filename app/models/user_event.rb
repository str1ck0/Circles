class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :payments

  enum status: { invited: 0, going: 1, maybe: 2, declined: 3 }

  validates :user_id, uniqueness: { scope: :event_id }

  def user_name
    user.first_name
  end
end
