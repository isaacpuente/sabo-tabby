# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "sabo_tabby/helpers"

module SaboTabby
  class Relationship
    extend Dry::Initializer
    include Helpers

    param :parent
    param :parent_mapper, default: proc { parent.mapper }
    param :parent_options, default: proc { parent.options }
    param :mappers, default: proc { parent.mappers }

    def call(scope, **scope_settings)
      return {} unless relationships?

      build(scope, **scope_settings)
    end

    private

    def build(scope, **scope_settings)
      mapper_rel_keys = parent_mapper.relationships.keys
      scope_settings
        .select { |k, _v| mapper_rel_keys.include?(k) }
        .each_with_object({}) do |(_name, settings), result|
          rel_scope = relationship_scope(scope, settings[:scope])
          rel = send(settings[:cardinality], rel_scope, scope, **settings)
          next if rel.nil? || rel.empty?

          result[settings[:key_name]] = {"data" => rel}.merge!(links(scope, **settings))
        end
    end

    def relationship_scope(scope, method_name)
      result = scope.send(method_name)
      result.is_a?(Numeric) ? id_object(result).new : result
    end

    def relationships?
      parent_mapper.relationships.any?
    end

    def one(scope, parent_scope, **settings)
      return {} if scope.nil?

      {"type" => settings[:type], "id" => scope.send(settings[:identifier]).to_s}
    end

    def many(scope, parent_scope, **settings)
      scope.flatten.map { |s| one(s, parent_scope, **settings) }
    end

    def links(scope, **settings)
      parent.link
        .for_relationship(scope, **settings)
        .then { |result| result.any? ? {"links" => result} : {} }
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
