module DataPlugins::Facet::Concerns::HasFacetItems

  extend ActiveSupport::Concern

  included do
    has_many :owner_facet_items, class_name: DataPlugins::Facet::OwnerFacetItem, as: :owner
    has_many :facet_items, class_name: DataPlugins::Facet::FacetItem, through: :owner_facet_items
    has_many :facets, class_name: DataPlugins::Facet::Facet, through: :facet_items
  end

  def facet_items_to_hash
    facet_items.map { |item| item.to_hash(attributes: nil, relationships: nil) }
  end

  module ClassMethods
  end

end
