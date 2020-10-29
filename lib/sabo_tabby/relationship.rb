# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Relationship
    extend Dry::Initializer
    extend Forwardable

    param :parent
    param :parent_mapper, default: proc { parent.mapper }
    param :options, default: proc { parent.options }
    param :scope_relationships, default: proc { {} }

    def call(scope)
      scope_relationships[scope.hash] ||= build(parent_mapper.relationships, scope)
    end

    def with(parent)
      self.class.new(parent)
    end

    private

    def build(relationships, scope)
      relationships.each_with_object({}) do |(name, opts), result|
        rel_scope = relationship_scope(scope, opts[:method])
        rel_name = opts.fetch(:as, opts[:method])
        next if skip?(rel_scope)

        result[rel_name] = {
          data: send(opts[:cardinality], opts.fetch(:as, name).to_s, rel_scope, **opts)
        }
      end
    end

    def relationship_scope(scope, method)
      if scope.respond_to?(method) && !skip?(scope.send(method))
        scope.send(method)
      elsif scope.respond_to?("#{method}_id") && !skip?(scope.send("#{method}_id"))
        id_object(scope, method).new
      end
    end

    def skip?(scope)
      scope.nil? || (scope.is_a?(Array) && scope.empty?)
    end

    def one(name, scope, **opts)
      mapper = parent.mappers[name]
      {type: opts.fetch(:type, mapper.type).to_s, id: scope.send(mapper.resource_identifier).to_s}
    end

    def many(name, scope, **opts)
      mapper_key = inflector.singularize(name)
      scope.map { |s| one(mapper_key, s, **opts) }
    end

    def inflector
      @inflector ||= SaboTabby::Container[:inflector]
    end

    def id_object(scope, method)
      Class.new do
        define_method :id do
          scope.send("#{method}_id")
        end
      end
    end
  end
end
