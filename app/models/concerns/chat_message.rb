# Shared by CircleMessage and EventMessage: a user says something in a chatroom.
module ChatMessage
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates :content, presence: true
  end

  def sender?(a_user)
    user_id == a_user&.id
  end
end
