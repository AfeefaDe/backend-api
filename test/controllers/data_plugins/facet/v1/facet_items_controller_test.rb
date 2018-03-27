require 'test_helper'

class DataPlugins::Facet::V1::FacetItemsControllerTest < ActionController::TestCase

  include ActsAsFacetItemControllerTest

  def create_root
    create(:facet, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_root_with_items
    create(:facet_with_items, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_root_with_items_and_sub_items
    create(:facet_with_items_and_sub_items, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_item_with_root(facet)
    create(:facet_item, facet: facet)
  end

  def get_root_items(facet)
    facet.facet_items
  end

  def get_owner_items(owner)
    owner.facet_items
  end

  def ownerClass
    DataPlugins::Facet::FacetItemOwner
  end

  def itemClass
    DataPlugins::Facet::FacetItem
  end

  def params(root, params)
    params[:facet_id] = root.id
    params
  end

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'throw 404 error on create with wrong params' do
      post :create, params: { facet_id: 1, title: 'new facet item' }
      assert_response :not_found
    end

    should 'update facet item with new facet and parent' do
      facet = create(:facet)
      facet2 = create(:facet)
      parent2 = create(:facet_item, facet: facet2)
      facet_item = create(:facet_item, facet: facet)

      assert_no_difference -> { DataPlugins::Facet::FacetItem.count } do
        patch :update, params: { facet_id: facet.id, id: facet_item.id, new_facet_id: facet2.id, parent_id: parent2.id, title: 'changed facet item' }
        assert_response :ok
      end

      json = JSON.parse(response.body)
      facet_item.reload
      assert_equal facet_item.facet_id, facet2.id
      assert_equal facet_item.parent_id, parent2.id
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'throw error if linking owner which is not supported by facet' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      event = create(:event)

      assert_no_difference -> { DataPlugins::Facet::FacetItemOwner.count } do
        post :link_owners, params: { facet_id: facet.id, owner_type: 'events', owner_id: event.id, id: facet_item.id }
        assert_response :unprocessable_entity
        assert response.body.blank?
      end
    end

    should 'not fail if linking multiple owners fails for one owner which type is not supported by facet' do
      facet = create(:facet, owner_types: ['Event'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      event = create(:event)

      assert_difference -> { DataPlugins::Facet::FacetItemOwner.count } do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'events', owner_id: event.id }
          ]
        }
        assert_response :created
        assert response.body.blank?

        assert_nil orga.facet_items.first
        assert_equal facet_item, event.facet_items.first
      end
    end

  end

end
