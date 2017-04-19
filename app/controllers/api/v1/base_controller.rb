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

  on_server_error do |error|
    # do custom code or debugging here
    # binding.pry
    # pp error
    # pp error.backtrace
  end

##############################

  before_action :find_objects, only: %i(index show)
  before_action :find_objects_for_related_to, only: %i(get_related_resources)
  before_action :filter_objects, only: %i(index show get_related_resources)

  def index
    render_objects_to_json
  end

  def show
    render json: { data: @objects.find(params[:id]).try(:to_hash) }
  end

  def get_related_resources
    render_objects_to_json
  end

  private

  def render_objects_to_json
    json_hash =
      @objects.try do |objects|
        objects.map do |object|
          object.try(:to_hash)
        end
      end || []
    render json: { data: json_hash }
  end

  def filter_params
    params.fetch(:filter, {}).permit(filter_whitelist + custom_filter_whitelist)
  end

  def filter_whitelist
    # raise NotImplementedError, 'Define filter whitelist in your class!'
    []
  end

  def custom_filter_whitelist
    []
  end

  def apply_custom_filter!(_filter, _filter_criterion, objects)
    objects
  end

  def base_for_find_objects
    nil
  end

  def default_filter
    {}
  end

  def find_objects_for_related_to
    related_to = params[:related_type].singularize.camelcase.constantize.find(params[:id])
    relation = self.class.name.to_s.split('::').last.gsub('Controller', '').underscore
    @objects = related_to.send(relation)
  end

  def find_objects
    @objects =
      base_for_find_objects ||
        self.class.name.to_s.split('::').last.gsub('Controller', '').singularize.constantize.all
  end

  def filter_objects
    filter_params.to_h.reverse_merge(default_filter).each do |filter, filter_criterion|
      if filter.to_s.in?(filter_whitelist)
        @objects = @objects.where("#{filter} LIKE ?", "%#{filter_criterion}%")
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

# def ensure_host
#   allowed_hosts = Settings.api.hosts
#   if (host = request.host).in?(allowed_hosts)
#     true
#   else
#     render(
#       text: "wrong host: #{host}, allowed: #{allowed_hosts.join(', ')}",
#       status: :unauthorized
#     )
#     false
#   end
# end
#
# def ensure_protocol
#   allowed_protocols = Settings.api.protocols
#   if (protocol = request.protocol.gsub(/:.*/, '')).in?(allowed_protocols)
#     true
#   else
#     render(
#       text: "wrong protocol: #{protocol}, allowed: #{allowed_protocols.join(', ')}",
#       status: :unauthorized
#     )
#     false
#   end
# end

# def ensure_admin_secret
#   if params[:admin_secret] == Settings.api.admin_secret
#     true
#   else
#     head :forbidden
#     false
#   end
# end

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
