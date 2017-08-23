require 'test_helper'

module Import
  class CsvTest < ActiveSupport::TestCase

    setup do
      # Import::Csv.stubs(:puts).returns(nil)
      @area = 'bautzen'
    end

    test 'import first element of csv file' do
      assert_difference 'Orga.count' do
        assert_difference 'ContactInfo.count' do
          assert_difference 'Location.count' do
            assert_equal 1,
              Import::Csv.import(file: Rails.root.join('test', 'data', 'csv', 'entries_de.csv').to_s, area: @area, limit: 1)
          end
        end
      end
      orga = Orga.last
      assert_equal 'TESTORGA', orga.title
      assert_equal @area, orga.area
      assert orga.active?
    end

    test 'import complete csv file' do
      file = Rails.root.join('test', 'data', 'csv', 'entries_de.csv').to_s
      csv = CSV.parse(File.read(file), headers: true)
      rows = csv.count

      assert_difference 'Orga.count', rows do
        assert_difference 'ContactInfo.count', rows do
          assert_difference 'Location.count', rows do
            assert_equal rows, Import::Csv.import(file: file, area: @area)
          end
        end
      end
      orga = Orga.last
      assert_equal 'TESTORGA4', orga.title
      assert_equal @area, orga.area
      assert orga.active?
    end

  end
end
