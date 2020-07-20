# frozen_string_literal: true

require "dry-initializer"
require "forwardable"
require "sabo_tabby/relationship"

module SaboTabby
  class Resource
    extend Dry::Initializer
    extend Forwardable

    def_delegators :mapper, :name, :type, :link, :meta

    param :mapper
    param :options, default: proc { EMPTY_HASH }
    param :mappers, default: proc { {name.to_s => mapper} }
    param :resource_document, default: proc { {} }
    param :resource_relationships, default: proc { {} }
    param :relationship, default: proc { SaboTabby::Relationship.new(self) }

    def id(scope)
      return scope if scope.is_a?(Integer)

      scope.send(mapper.resource_identifier)
    end

    def attributes(scope)
      mapper
        .attributes
        .each_with_object({}) { |attribute, result| result[attribute] = scope.send(attribute) }
        .then { |attrs| dynamic_attributes? ? attrs.merge!(dynamic_attributes(scope)) : attrs }
    end

    def dynamic_attributes(scope)
      mapper
        .dynamic_attributes
        .each_with_object({}) do |(*attributes, block), result|
          attributes.each do |attr|
            value = scope.respond_to?(attr) ? scope.send(attr) : nil
            result[attr] = block.(value, scope, **options)
          end
        end
    end

    def document(scope)
      resource_document["#{type}_#{id(scope)}"] ||=
        identifier(scope)
          .then { |doc| attributes? ? doc.merge!(attributes: attributes(scope)) : doc }
          .then { |doc| meta? ? doc.merge!(meta(scope)) : doc }
          .then { |doc| relationships? ? doc.merge!(relationships(scope)) : doc }
    end

    def identifier(scope)
      {id: id(scope).to_s, type: type.to_s}
    end

    def relationships(scope)
      relationship.call(scope)
    end

    def meta(_scope = nil)
      {meta: mapper.meta}
    end

    def with(mappers: {}, **opts)
      tap {
        @mappers = mappers if mappers.any?
        @options = opts
      }
    end

    def relationships?
      mapper.relationships.one.any? || mapper.relationships.many.any?
    end

    def attributes?
      mapper.attributes.any?
    end

    def dynamic_attributes?
      mapper.respond_to?(:dynamic_attributes) && mapper.dynamic_attributes.any?
    end

    def meta?
      mapper.meta.any?
    end
  end
end
