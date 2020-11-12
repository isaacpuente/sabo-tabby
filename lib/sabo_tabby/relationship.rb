# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Relationship
    extend Dry::Initializer
    # extend Forwardable

    # param :parent
    # param :parent_mapper, default: proc { parent.mapper }
    # param :options, default: proc { parent.options }
    # param :scope_relationships, default: proc { {} }

    def call(mapper, scope, **scope_settings)
      return {} unless relationships?(mapper)

      build(mapper, scope, **scope_settings)
    end

    private

    def build(mapper, scope, **scope_settings)
      mapper_rel_keys = mapper.relationships.keys
      scope_settings
        .select { |k, _v| mapper_rel_keys.include?(k) }
        .each_with_object({}) do |(name, settings), result|
          rel = send(
            settings[:cardinality],
            relationship_scope(scope, settings[:scope]),
            **settings
          )
          next if rel.nil? || rel.empty?

          result[name] = {data: rel}
        end
    end

    def relationship_scope(scope, method_name)
      result = scope.send(method_name)
      result.is_a?(Numeric) ? id_object(result).new : result
    end

    def relationships?(mapper)
      mapper.relationships.any?
    end

    def one(scope, **settings)
      return {} if scope.nil?

      {type: settings[:type].to_s, id: scope.send(settings[:identifier]).to_s}
    end

    def many(scope, **settings)
      scope.map { |s| one(s, **settings) }
    end

    def inflector
      @inflector ||= SaboTabby::Container[:inflector]
    end

    def id_object(id)
      Class.new do
        define_method :id do
          id
        end
      end
    end
  end
end
