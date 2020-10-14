# frozen_string_literal: true

# auto_register: false

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
      return "" unless scope.respond_to?(mapper.resource_identifier)

      scope.send(mapper.resource_identifier)
    end

    def attributes(scope)
      attributes = mapper
        .attributes
        .each_with_object({}) do |attribute, result|
          next unless scope.respond_to?(attribute)

          result[attribute] = scope.send(attribute)
        end
      dynamic_attributes? ? attributes.merge!(dynamic_attributes(scope)) : attributes
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
      #resource_document[document_id(scope)] ||=
      resource_document[scope.hash] ||=
        identifier(scope)
          .then { |doc| attributes? ? doc.merge!(attributes: attributes(scope)) : doc }
          .then { |doc| meta? ? doc.merge!(meta(scope)) : doc }
          .then { |doc| relationships? ? doc.merge!(relationships(scope)) : doc }
    end

    def identifier(scope)
      {type: type.to_s, id: id(scope).to_s}
    end

    def relationships(scope)
      # p "*********************************"
      # p Benchmark.bm { |x|
      #   x.report("relationships") { relationship.call(scope) }
      # }

      #resource_relationships[document_id(scope)] ||= relationship.call(scope)
      resource_relationships[scope.hash] ||= relationship.call(scope)
    end

    def meta(_scope = nil)
      {meta: mapper.meta}
    end

    def relationships?
      mapper.relationships.one.any? || mapper.relationships.many.any?
    end

    def attributes?
      mapper.attributes.any? || dynamic_attributes?
    end

    def dynamic_attributes?
      mapper.respond_to?(:dynamic_attributes) && mapper.dynamic_attributes.any?
    end

    def meta?
      mapper.meta.any?
    end

    def document_id(scope)
      "#{type}_#{id(scope)}"
    end
  end
end
