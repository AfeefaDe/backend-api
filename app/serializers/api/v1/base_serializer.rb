class Api::V1::BaseSerializer < JSONAPI::ResourceSerializer

  def initialize(operation_results, options = {})
    super
    if serialize_options = options.fetch(:serialization_options, {})
      @include_linkage_whitelist = serialize_options[:include_linkage_whitelist]
      @action = serialize_options[:action]
    end
  end

  def serialize_to_hash(source)
    super
  end

  private

  def relationships_hash(source, include_directives)
    super
  end

  def link_object_to_one(source, relationship, include_linkage)
    include_linkage = include_linkage || include_linkage?
    super(source, relationship, include_linkage)
  end

  def link_object_to_many(source, relationship, include_linkage)
    include_linkage = include_linkage || include_linkage?
    super(source, relationship, include_linkage)
  end

  def to_many_linkage(source, relationship)
    # binding.pry if source.class.to_s == 'Api::V1::AnnotationResource'
    data = super
    # binding.pry
    # ATTENTION: This does only work for non-polymorphic associations because
    # we do not persist the __id__ attribute in the database
    source.public_send(relationship.name).each_with_index do |value, index|
      if value._model.respond_to?(:internal_id) && value._model.internal_id
        data[index][:attributes] = { __id__: value._model.internal_id }
      end
    end
    # binding.pry
    data
  end

  def include_linkage?
    # ATTENTION: not for entries (=todos)! → if this is trouble for us:
    # return false if self.instance_variable_get('@primary_resource_klass') == Api::V1::EntryResource
    @action.in?(@include_linkage_whitelist)
  end

end
