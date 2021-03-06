class Api::V1::EntriesBaseResource < Api::V1::BaseResource

  abstract

  ATTRIBUTES = [
    :title, :description, :short_description, :created_at, :updated_at,
    :contact_spec,
    :media_url, :media_type, :support_wanted, :support_wanted_detail,
    :certified_sfr, :tags,
    :state_changed_at, :active, :inheritance, :facebook_id]
  # define attributes in sub class like this:
  # attributes *ATTRIBUTES
  # or
  # attributes *(ATTRIBUTES + [:foo, :bar])

  has_one :category
  has_one :sub_category, class_name: 'Category'
  has_one :creator, class_name: 'User'
  has_one :last_editor, class_name: 'User'

  def active
    _model.state == StateMachine::ACTIVE.to_s
  end

end
