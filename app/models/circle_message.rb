class CircleMessage < ApplicationRecord
  include ChatMessage

  belongs_to :circle
end
