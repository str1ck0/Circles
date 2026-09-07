class EventMessage < ApplicationRecord
  include ChatMessage

  belongs_to :event
end
