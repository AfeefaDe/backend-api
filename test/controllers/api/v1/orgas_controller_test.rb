require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      # useful sample data
      orga = create(:orga)
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga))

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
      assert_equal Orga.last.to_hash.deep_stringify_keys, json['data'].last
      assert_equal Orga.last.active, json['data'].last['attributes']['active']

      assert_not json['data'].last['attributes'].key?('support_wanted_detail')
      assert_not json['data'].last['relationships'].key?('resources')
    end

    should 'get index only data of area of user' do
      user = @controller.current_api_v1_user

      # useful sample data
      orga = create(:orga, area: user.area + ' is different', parent: nil)
      assert_not_equal orga.area, user.area
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga, area: 'foo'))

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      assert orga.update(area: user.area)

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.by_area(user.area).count, json['data'].size
      orga_from_db = Orga.by_area(user.area).last
      assert_equal orga_from_db.to_hash.deep_stringify_keys, json['data'].last
      assert_equal orga_from_db.active, json['data'].last['attributes']['active']
    end

    should 'get title filtered list for orgas' do
      user = create(:user)
      orga0 = create(:orga, title: 'Hackathon', description: 'Mate fuer alle!')
      orga1 = create(:orga, title: 'Montagscafe', description: 'Kaffee und so im Schauspielhaus')
      orga2 = create(:orga, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten')

      get :index, params: { filter: { title: 'Garten' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size

      get :index, params: { filter: { title: 'foo' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size
    end

    should 'not get show root_orga' do
      not_existing_id = 999
      assert Orga.where(id: not_existing_id).blank?
      get :show, params: { id: not_existing_id }
      assert_response :not_found, response.body
    end

    should 'I want to create a new orga' do
      params = parse_json_file do |payload|
        payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
        payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
        payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
      end
      params['data']['attributes'].merge!('active' => true)

      assert_difference 'Orga.count' do
        assert_no_difference 'AnnotationCategory.count' do
          assert_difference 'Annotation.count', 2 do
            post :create, params: params
            assert_response :created, response.body
          end
        end
      end
      json = JSON.parse(response.body)
      assert_equal StateMachine::ACTIVE.to_s, Orga.last.state
      assert_equal true, json['data']['attributes']['active']

      # Then we could deliver the mapping there
      %w(annotations contacts).each do |relation|
        assert json['data']['relationships'][relation].key?('data'), "No element for relation #{relation} found."
        to_check = json['data']['relationships'][relation]['data'].first
        assert_equal relation, to_check['type'] if to_check
      end

      user = @controller.current_api_v1_user
      assert_equal user.area, Orga.last.area
      assert_equal user.id, Orga.last.creator_id
      assert_equal user.id, Orga.last.last_editor_id
      assert_equal user.id.to_s, json['data']['relationships']['creator']['data']['id']
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'get show' do
        get :show, params: { id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal false, json['data']['attributes']['active']
        assert_equal Orga.attribute_whitelist_for_json.sort, json['data']['attributes'].symbolize_keys.keys.sort
        assert_equal Orga.relation_whitelist_for_json.sort, json['data']['relationships'].symbolize_keys.keys.sort
      end

      should 'get show with resources' do
        resource = ResourceItem.create!(title: 'test resource', description: 'demo test', orga: @orga)

        get :show, params: { id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal false, json['data']['attributes']['active']
        assert_equal Orga.attribute_whitelist_for_json.sort, json['data']['attributes'].symbolize_keys.keys.sort
        assert_equal Orga.relation_whitelist_for_json.sort, json['data']['relationships'].symbolize_keys.keys.sort
      end

      should 'update should fail for invalid' do
        assert_no_difference 'Orga.count' do
          assert_no_difference 'AnnotationCategory.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                post :create, params: {
                  data: {
                    type: 'orgas',
                    attributes: {
                    },
                    relationships: {
                    }
                  }
                }
                assert_response :unprocessable_entity, response.body
                json = JSON.parse(response.body)
                assert_equal(
                  [
                    'Titel - fehlt',
                    'Kurzbeschreibung - fehlt'
                  ],
                  json['errors'].map { |x| x['detail'] }
                )
              end
            end
          end
        end
      end

      should 'update orga with nested attributes' do
        creator = create(:user)
        orga = create(:orga, title: 'foobar', creator_id: creator.id)
        assert_difference 'Annotation.count' do
          Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
        end
        annotation = orga.reload.annotations.last
        assert_difference 'ResourceItem.count' do
          ResourceItem.create!(title: 'ganz wichtige Ressource', orga: orga)
        end
        resource = orga.reload.resource_items.last

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Annotation.count' do
            assert_no_difference 'AnnotationCategory.count' do
              assert_no_difference 'ResourceItem.count' do
                post :update,
                  params: {
                    id: orga.id,
                  }.merge(
                    parse_json_file(
                      file: 'update_orga_with_nested_models.json'
                    ) do |payload|
                      payload.gsub!('<id>', orga.id.to_s)
                      payload.gsub!('<annotation_id_1>', annotation.id.to_s)
                      payload.gsub!('<resource_id_1>', resource.id.to_s)
                      payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
                      payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
                    end
                  )
                assert_response :ok, response.body
              end
            end
          end
        end
        assert_equal 'Ein Test 3', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
        assert_equal 1, Orga.last.annotations.count
        assert_equal annotation, Orga.last.annotations.first
        assert_equal 'foo-bar', annotation.reload.detail
        assert_equal 1, Orga.last.resource_items.count
        assert_equal resource, Orga.last.resource_items.first
        assert_equal 'foo-bar', resource.reload.title

        user = @controller.current_api_v1_user
        assert_not_equal creator.id, user.id
        assert_equal user.area, Orga.last.area
        assert_equal creator.id, Orga.last.creator_id # kept
        assert_equal user.id, Orga.last.last_editor_id

        json = JSON.parse(response.body)
        assert_equal creator.id.to_s, json['data']['relationships']['creator']['data']['id']
        assert_equal user.id.to_s, json['data']['relationships']['last_editor']['data']['id']
      end

      should 'deactivate an inactive invalid orga' do
        orga = create(:orga, title: 'foobar')
        orga.title = nil
        assert_not orga.valid?
        assert orga.save(validate: false)

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'Annotation.count' do
                assert_no_difference 'AnnotationCategory.count' do
                  post :update,
                    params: {
                      id: orga.id,
                    }.merge(
                      parse_json_file(
                        file: 'deactivate_orga.json'
                      ) do |payload|
                        payload.gsub!('<id>', orga.id.to_s)
                      end
                    )
                  assert_response :ok, response.body
                end
              end
            end
          end
        end
        assert orga.reload.inactive?
        assert orga.title.blank?
      end

      should 'deactivate an active invalid orga' do
        orga = create(:orga, title: 'foobar')
        orga.title = nil
        orga.state = StateMachine::ACTIVE
        assert_not orga.valid?
        assert orga.save(validate: false)
        assert orga.reload.active?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'Annotation.count' do
                assert_no_difference 'AnnotationCategory.count' do
                  post :update,
                    params: {
                      id: orga.id,
                    }.merge(
                      parse_json_file(
                        file: 'deactivate_orga.json'
                      ) do |payload|
                        payload.gsub!('<id>', orga.id.to_s)
                      end
                    )
                  assert_response :ok, response.body
                end
              end
            end
          end
        end
        assert orga.reload.inactive?
        assert orga.title.blank?
      end

      should 'update orga and remove annotations' do
        # this is needed for empty arrays in params,
        # see: http://stackoverflow.com/questions/40870882/rails-5-params-with-object-having-empty-arrays-as-values-are-dropped
        @request.headers['Content-Type'] = 'application/json'

        orga = create(:orga, title: 'foobar')
        Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
        annotation = orga.reload.annotations.last

        assert_no_difference 'Orga.count' do
          assert_no_difference 'AnnotationCategory.count' do
            assert_difference 'Annotation.count', -1 do
              post :update,
                params: {
                  id: orga.id,
                }.merge(
                  parse_json_file(
                    file: 'update_orga_remove_annotations.json'
                  ) do |payload|
                    payload.gsub!('<id>', orga.id.to_s)
                    payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
                    payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
                  end
                )
              assert_response :ok, response.body
            end
          end
        end
        assert_equal 'Ein Test 3', orga.reload.title
        assert_equal Orga.root_orga.id, orga.parent_orga_id
        assert_equal 0, orga.annotations.count
        assert_nil Annotation.where(id: annotation.id).first
      end

      should 'destroy orga' do
        assert @orga.locations.any?
        skip 'destroy of locations on orga destroy needs to be implemented'
        assert_difference 'Orga.count', -1 do
          assert_difference 'Orga.undeleted.count', -1 do
            assert_difference 'ContactInfo.count', -1 do
              assert_difference -> { DataPlugins::Location::Location.count }, -1 do
                assert_no_difference 'AnnotationCategory.count' do
                  delete :destroy,
                    params: {
                      id: @orga.id,
                    }
                  assert_response :no_content, response.body
                end
              end
            end
          end
        end
      end

      should 'not destroy orga with associated sub_orga' do
        assert sub_orga = create(:another_orga, parent_id: @orga.id)
        assert_equal @orga.id, sub_orga.parent_id
        assert @orga.reload.sub_orgas.any?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                assert_no_difference 'AnnotationCategory.count' do
                  delete :destroy,
                    params: {
                      id: @orga.id,
                    }
                  assert_response :locked, response.body
                  json = JSON.parse(response.body)
                  assert_equal 'Unterorganisationen müssen gelöscht werden', json['errors'].first['detail']
                end
              end
            end
          end
        end
      end

      should 'not destroy orga with associated event' do
        assert event = create(:event, orga_id: @orga.id)
        assert_equal @orga.id, event.orga_id
        assert @orga.reload.events.any?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'Orga.undeleted.count' do
            assert_no_difference 'Event.count' do
              assert_no_difference 'Event.undeleted.count' do
                assert_no_difference 'ContactInfo.count' do
                  assert_no_difference 'Location.count' do
                    assert_no_difference 'AnnotationCategory.count' do
                      delete :destroy,
                        params: {
                          id: @orga.id,
                        }
                      assert_response :locked, response.body
                      json = JSON.parse(response.body)
                      assert_equal 'Events müssen gelöscht werden', json['errors'].first['detail']
                    end
                  end
                end
              end
            end
          end
        end
      end

      should 'create new orga with parent relation and inheritance' do
        params = parse_json_file file: 'create_orga_with_parent.json' do |payload|
          payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
          payload.gsub!('<parent_orga_id>', @orga.id.to_s)
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
        end

        assert_not_nil params['data']['attributes']['inheritance']
        inh = params['data']['attributes']['inheritance']

        assert_difference 'Orga.count' do
          post :create, params: params
          assert_response :created, response.body
        end

        response_json = JSON.parse(response.body)
        new_orga_id = response_json['data']['id']

        assert_equal Orga.find(new_orga_id).parent_orga, @orga

        #todo: ticket #276 somehow in create methode parent_orga is set to 1 (ROOT_ORGA) so inheritance gets unset, but WHY!!! #secondsave
        assert_equal inh, response_json['data']['attributes']['inheritance']
        assert_not_nil response_json['data']['attributes']['inheritance']
      end

      should 'create new orga with resources' do
        params = parse_json_file file: 'create_orga_with_nested_models.json' do |payload|
          payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
        end

        assert_difference 'Orga.count' do
          assert_difference 'ResourceItem.count', 2 do
            post :create, params: params
            assert_response :created, response.body
          end
        end

        response_json = JSON.parse(response.body)
        new_orga_id = response_json['data']['id']

        resources = ResourceItem.order(id: :desc)[0..1]
        resources.each do |resource|
          assert_equal new_orga_id.to_s, resource.orga_id.to_s
        end
      end

      should 'add project association' do
        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.project.count } do
            post :add_project, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end
        new_relation = DataModules::Actor::ActorRelation.last
        assert_equal @orga, new_relation.associating_actor
        assert_equal Orga.last, new_relation.associated_actor
        assert_equal DataModules::Actor::ActorRelation::PROJECT.to_s, new_relation.type
      end

      should 'remove project association' do
        generate_association!(@orga.id, Orga.last.id, DataModules::Actor::ActorRelation::PROJECT)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.count }, -1 do
            delete :remove_project, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :ok, response.body
            assert response.body.blank?
          end
        end
        relation =
          DataModules::Actor::ActorRelation.where(
            associating_actor_id: @orga.id,
            associated_actor_id: Orga.last.id,
            type: DataModules::Actor::ActorRelation::PROJECT.to_s)
        assert relation.blank?
      end

      should 'handle remove of not existing project association' do
        delete :remove_project, params: { id: @orga.id, item_id: Orga.last.id }
        assert_response :not_found, response.body
        assert response.body.blank?
      end

      should 'add network_member association' do
        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.count } do
            post :add_network_member, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end
        new_relation = DataModules::Actor::ActorRelation.last
        assert_equal @orga, new_relation.associating_actor
        assert_equal Orga.last, new_relation.associated_actor
        assert_equal DataModules::Actor::ActorRelation::NETWORK.to_s, new_relation.type
      end

      should 'remove network_member association' do
        generate_association!(@orga.id, Orga.last.id, DataModules::Actor::ActorRelation::NETWORK)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.count }, -1 do
            delete :remove_network_member, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :ok, response.body
            assert response.body.blank?
          end
        end
        relation =
          DataModules::Actor::ActorRelation.where(
            associating_actor_id: @orga.id,
            associated_actor_id: Orga.last.id,
            type: DataModules::Actor::ActorRelation::NETWORK.to_s)
        assert relation.blank?
      end

      should 'handle remove of not existing network_member association' do
        delete :remove_network_member, params: { id: @orga.id, item_id: Orga.last.id }
        assert_response :not_found, response.body
        assert response.body.blank?
      end

      should 'add partner association' do
        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.count } do
            post :add_partner, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :created, response.body
            assert response.body.blank?
          end
        end
        new_relation = DataModules::Actor::ActorRelation.last
        assert_equal @orga, new_relation.associating_actor
        assert_equal Orga.last, new_relation.associated_actor
        assert_equal DataModules::Actor::ActorRelation::PARTNER.to_s, new_relation.type
      end

      should 'remove partner association' do
        generate_association!(@orga.id, Orga.last.id, DataModules::Actor::ActorRelation::PARTNER)

        assert_no_difference -> { Orga.count } do
          assert_difference -> { DataModules::Actor::ActorRelation.count }, -1 do
            delete :remove_partner, params: { id: @orga.id, item_id: Orga.last.id }
            assert_response :ok, response.body
            assert response.body.blank?
          end
        end
        relation =
          DataModules::Actor::ActorRelation.where(
            associating_actor_id: @orga.id,
            associated_actor_id: Orga.last.id,
            type: DataModules::Actor::ActorRelation::PARTNER.to_s)
        assert relation.blank?
      end

      should 'handle remove of not existing partner association' do
        delete :remove_partner, params: { id: @orga.id, item_id: Orga.last.id }
        assert_response :not_found, response.body
        assert response.body.blank?
      end
    end
  end

  private

  def generate_association!(left_id, right_id, type)
    DataModules::Actor::ActorRelation.create(
      associating_actor_id: left_id,
      associated_actor_id: right_id,
      type: type
    )
  end

end
