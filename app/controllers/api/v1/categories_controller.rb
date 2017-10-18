class Api::V1::CategoriesController < Api::V1::BaseController

  private

  def apply_custom_filter!(filter, filter_criterion, objects)
    objects =
      case filter.to_sym
      when :area
        objects.by_area(filter_criterion)
      else
        objects
      end
    objects
  end

  def custom_filter_whitelist
    %w(area).freeze
  end

  def default_filter
    { area: current_api_v1_user.area }
  end

  def do_includes!(objects)
    objects =
      objects.includes(:parent)
    objects
  end

end
