module DataPlugins::Facet
  class Facet < ApplicationRecord

    include Jsonable

    # ASSOCIATIONS
    has_many :facet_items, dependent: :destroy
    has_many :facet_item_owners, class_name: DataPlugins::Facet::FacetItemOwner, through: :facet_items
    has_many :owner_types, class_name: DataPlugins::Facet::FacetOwnerType, dependent: :destroy

    def owners
      facet_item_owners.map(&:owner)
    end

    # VALIDATIONS
    validates :title, length: { maximum: 255 }

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title color color_sub_items main_facet_of).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(owner_types facet_items).freeze
      end

      def facet_params(params)
        params.permit(:title, :color, :color_sub_items)
      end

      def save_facet(params)
        facet = find_or_initialize_by(id: params[:id])
        facet.assign_attributes(facet_params(params))
        facet.save!
        facet
      end
    end

    def facet_items_to_hash(attributes: nil, relationships: nil)
      items = facet_items.select { |item| item.parent_id == nil }
      items.map { |item| item.to_hash(attributes: item.class.default_attributes_for_json) }
    end

    def main_facet_of_to_hash(attributes: nil, relationships: nil)
      main_owner_type = owner_types.find { |owner_type| owner_type.main_facet == true }
      return main_owner_type ? main_owner_type.owner_type : nil
    end

    def owner_types_to_hash(attributes: nil, relationships: nil)
      owner_types.map { |owner_type| owner_type.owner_type }
    end

  end
end
