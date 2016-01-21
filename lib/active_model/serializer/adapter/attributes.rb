module ActiveModel
  class Serializer
    module Adapter
      class Attributes < Base
        def initialize(serializer, options = {})
          super
          @include_tree = IncludeTree.from_include_args(
            options[:include] || ActiveModel::Serializer.config.default_include_tree
          )
        end

        def serializable_hash(options = nil)
          options ||= {}

          if serializer.respond_to?(:each)
            serializable_hash_for_collection(options)
          else
            serializable_hash_for_single_resource(options)
          end
        end

        def fragment_cache(cached_hash, non_cached_hash)
          Json::FragmentCache.new.fragment_cache(cached_hash, non_cached_hash)
        end

        private

        def serializable_hash_for_collection(options)
          serializer.map { |s| Attributes.new(s, instance_options).serializable_hash(options) }
        end

        def serializable_hash_for_single_resource(options)
          resource = resource_object_for(options)
          relationships = resource_relationships(options)
          resource.merge!(relationships)
        end

        def resource_relationships(options)
          relationships = {}
          excepts = Array(options[:except])
          serializer.associations(@include_tree).each do |association|
            next if excepts.include?(association.key)
            relationships[association.key] = relationship_value_for(association, options)
          end

          relationships
        end

        def relationship_value_for(association, options)
          return association.options[:virtual_value] if association.options[:virtual_value]
          return unless association.serializer && association.serializer.object

          opts = instance_options.merge(include: @include_tree[association.key])
          hash_opts = options.merge(except: association.options[:except])
          Attributes.new(association.serializer, opts).serializable_hash(hash_opts)
        end

        # no-op: Attributes adapter does not include meta data, because it does not support root.
        def include_meta(json)
          json
        end

        def resource_object_for(options)
          cache_check(serializer) do
            serializer.attributes(
              only: options[:fields],
              except: options[:except])
          end
        end
      end
    end
  end
end
