require 'test_helper'

class TranslationCacheTest < ActiveSupport::TestCase

  should 'rebuild cache' do
    Settings.phraseapp.stubs(:active).returns(true)

    translations = nil

    VCR.use_cassette('get_all_translations') do
      translations = client.get_all_translations(Translatable::TRANSLATABLE_LOCALES)
    end

    VCR.use_cassette('rebuild_translation_cache') do
      assert translations.any?
      changes = TranslationCache.rebuild_db_cache!(translations)

      assert_equal translations.count, changes

      countTranslatedDbFields = TranslationCache.where.not(title: nil).count + TranslationCache.where.not(short_description: nil).count
      assert_equal translations.count, countTranslatedDbFields

      assert_equal 0, TranslationCache.where(language: Translatable::DEFAULT_LOCALE).count
    end
  end

  private

  def client
    @@client ||= PhraseAppClient.new
  end

end
