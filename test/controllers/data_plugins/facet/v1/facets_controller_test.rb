require 'test_helper'

class DataPlugins::Facet::V1::FacetsControllerTest < ActionController::TestCase
  setup do
    stub_current_user
  end

  test 'get facets' do
    DataPlugins::Facet::Facet.delete_all
    10.times do
      create(:facet)
    end

    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['data']
    assert_equal 10, json['data'].count
  end

  test 'get single facet' do
    facet = create(:facet)

    get :show, params: { id: facet.id }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal JSON.parse(facet.to_json), json['data']
  end

  test 'create facet' do
    assert_difference -> { DataPlugins::Facet::Facet.count } do
      post :create, params: { title: 'new facet' }
      assert_response :created
    end
    json = JSON.parse(response.body)
    facet = DataPlugins::Facet::Facet.last
    assert_equal JSON.parse(facet.to_json), json
  end

  test 'update facet' do
    facet = create(:facet)

    assert_no_difference -> { DataPlugins::Facet::Facet.count } do
      patch :update, params: { id: facet.id, title: 'changed facet' }
      assert_response :ok
    end
    json = JSON.parse(response.body)
    facet.reload
    assert_equal JSON.parse(facet.to_json), json
  end

  test 'remove facet' do
    facet = create(:facet)

    assert_difference -> { DataPlugins::Facet::Facet.count }, -1 do
      delete :destroy, params: { id: facet.id }
      assert_response 200
    end
    assert response.body.blank?
  end
end
