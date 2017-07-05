class Api::V1::BaseController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include JSONAPI::ActsAsResourceController
  include CustomHeaders

  respond_to :json

  before_action :authenticate_api_v1_user!
  before_action :permit_params

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  # on_server_error do |error|
    # do custom code or debugging here
    # binding.pry
    # pp error
    # pp error.backtrace
  # end

##############################

  before_action :find_objects, only: %i(index show update)
  before_action :find_objects_for_related_to, only: %i(get_related_resources)
  before_action :filter_objects, only: %i(index show get_related_resources)

  def index
    render_objects_to_json(@objects)
  end

  def show
    object = @objects.find(params[:id])
    render_single_object_to_json(object)
  end

  def get_related_resources
    render_objects_to_json(@objects)
  end

  def update
    params_hash = params['data']['attributes'].to_unsafe_h
    if params_hash.in?([{ 'active' => 'false' }, { 'active' => 'false' }]) &&
        !params['data'].key?('relationships')
      object = @objects.find(params[:id])
      active = params_hash['active']

      success = true
      if object.active? && active.to_s == 'false'
        success = object.deactivate!
      elsif object.inactive? && active.to_s == 'true'
        success = object.activate!
      end

      if success
        render_single_object_to_json(object)
      else
        render_errors(object.errors)
      end
    else
      super
    end
  end

  private

  def render_objects_to_json(objects)
    json_hash =
      objects.try do |objects_in_try|
        objects_in_try.map do |object|
          object.try(:send, to_hash_method)
        end
      end || []
    render json: { data: json_hash }
  end

  def render_single_object_to_json(object)
    render json: {
      data: object.send(to_hash_method,
        attributes: object.class.attribute_whitelist_for_json,
        relationships: object.class.relation_whitelist_for_json)
    }
  end

  def to_hash_method
    :to_hash
  end

  def filter_params
    params.fetch(:filter, {}).permit(filter_whitelist + custom_filter_whitelist)
  end

  def filter_whitelist
    # raise NotImplementedError, 'Define filter whitelist in your class!'
    [].freeze
  end

  def custom_filter_whitelist
    [].freeze
  end

  def apply_custom_filter!(_filter, _filter_criterion, objects)
    objects
  end

  def base_for_find_objects
    nil
  end

  def default_filter
    {}.freeze
  end

  def find_objects_for_related_to
    related_to = params[:related_type].singularize.camelcase.constantize.find(params[:id])
    relation = self.class.name.to_s.split('::').last.gsub('Controller', '').underscore
    @objects = related_to.send(relation)
  end

  def find_objects
    @objects =
      base_for_find_objects ||
        get_model_class_for_controller.all
  end

  def get_model_class_for_controller
    self.class.name.to_s.split('::').last.gsub('Controller', '').singularize.constantize
  end

  def filter_objects
    filter_params.to_h.reverse_merge(default_filter).each do |filter, filter_criterion|
      if filter.to_s.in?(filter_whitelist)
        if filter_criterion.present?
          @objects = @objects.where("#{filter} LIKE ?", "%#{filter_criterion}%")
        else
          @objects = @objects.none
        end
      elsif filter.to_s.in?(custom_filter_whitelist)
        @objects = apply_custom_filter!(filter, filter_criterion, @objects)
      end
    end

    @objects = do_includes!(@objects)
  end

  def do_includes!(objects)
    objects
  end

###############################

  def permit_params
    params.try(:[], :data).try(:[], :attributes).try(:delete, :state)
    params.try(:[], :data).try(:[], :relationships).try(:delete, :creator)
  end

  def render_results(operation_results)
    response_doc = create_response_document(operation_results)
    content = response_doc.contents

    if content.blank? || content.key?(:data) && content[:data].nil?
      error =
        JSONAPI::Exceptions::RecordNotFound.new(params[:id].presence || '(id not given)')
      render_errors(error.errors)
    else
      super
    end
  end

  def context
    { current_user: current_api_v1_user }
  end

  def resource_serializer_klass
    @resource_serializer_klass ||= Api::V1::BaseSerializer
  end

  def render_results(operation_results)
    # binding.pry
    super
  end

  def render_errors(errors)
    super
  end

  def serialization_options
    # binding.pry
    super.merge(
      include_linkage_whitelist: %i(create update show index),
      action: params[:action].to_sym)
  end

end
