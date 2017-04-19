class Api::V1::ContactInfoResource < Api::V1::BaseResource

  model_name 'ContactInfo'

  attributes :mail, :phone, :contact_person, :created_at, :updated_at,
    :web, :facebook, :opening_hours
  attribute :__id__, delegate: :internal_id

  has_one :contactable, polymorphic: true
end
