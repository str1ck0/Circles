class Payment < ApplicationRecord
  belongs_to :user_event
  has_many :splittees, dependent: :destroy
  has_many :user_events, through: :splittees

  validates :description, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
end
