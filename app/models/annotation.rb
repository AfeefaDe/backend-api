class Annotation < ApplicationRecord
  belongs_to :annotatable, polymorphic: true
  # belongs_to :orga, inverse_of: :annotation
  # belongs_to :event, inverse_of: :annotation
end