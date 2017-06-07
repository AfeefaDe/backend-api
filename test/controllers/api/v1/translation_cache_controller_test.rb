require 'test_helper'

class Api::V1::TranslationCacheControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get last updated timestamp' do
      get :index

      json = JSON.parse(response.body)
      assert_equal TranslationCache.minimum(:updated_at) || Time.at(0), json['updated_at']
    end

    should 'trigger cache update' do
      get :index, params: {token: Settings.translations.api_token}
      assert_response :ok
      time_before = JSON.parse(response.body)['updated_at']

      post :update
      post_response = response.status

      get :index, params: {token: Settings.translations.api_token}

      case post_response
        when 200 # caching table got updated –> timestamp changed
          assert_operator time_before, :<, JSON.parse(response.body)['updated_at']
        when 204 # no updated was necessary -> nothing changed
          assert_equal time_before, JSON.parse(response.body)['updated_at']
        when 422
          fail 'a PhraseApp error occured'
        else
          fail 'unexpacted behavior on translation cache update'
      end

      # caching table contains no 'de' entries
      assert_nil TranslationCache.find_by(language: Translatable::DEFAULT_LOCALE)

    end
  end
end