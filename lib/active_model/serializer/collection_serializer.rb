module ActiveModel
  class Serializer
    class CollectionSerializer
      NoSerializerError = Class.new(StandardError)
      include Enumerable
      delegate :each, to: :@serializers

      attr_reader :object, :root

      def initialize(resources, options = {})
        @root = options[:root]
        @object = resources
        @instance_options = options

        each_serializer = options[:serializer]
        unless each_serializer
          serializer_context_class = options.fetch(:serializer_context_class, ActiveModel::Serializer)
        end

        @serializers = resources.map do |resource|
          serializer_class = each_serializer || serializer_context_class.serializer_for(resource)

          if serializer_class.nil?
            fail NoSerializerError, "No serializer found for resource: #{resource.inspect}"
          else
            serializer_class.new(resource, options.except(:serializer))
          end
        end
      end

      def json_key
        key = root || serializers.first.try(:json_key) || object.try(:name).try(:underscore)
        key.try(:pluralize)
      end

      def paginated?
        object.respond_to?(:current_page) &&
          object.respond_to?(:total_pages) &&
          object.respond_to?(:size)
      end

      protected

      attr_reader :instance_options, :serializers
    end
  end
end
