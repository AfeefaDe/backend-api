class EventSerializer < BaseSerializer

  attribute 'title'
  attribute 'description'
  attribute 'created_at'
  attribute 'updated_at'

  has_many :contact_infos, as: :contactable
  # belongs_to :thingable do
  #   # link :related, "/api/v1/orgas/#{object.id}/users"
  #   include_data false
  # end

  link :self do
    "/api/v1/events/#{object.id}"
  end
end