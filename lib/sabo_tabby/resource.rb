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
    param :relationship, default: proc { SaboTabby::Relationship.new(self) }

    def id(scope)
      return scope if scope.is_a?(Integer)
      return "" unless scope.respond_to?(mapper.resource_identifier)

      scope.send(mapper.resource_identifier)
    end

    def attributes(scope)
      return {} unless attributes?

      attributes = filter(mapper.attributes)
        .each_with_object({}) do |attribute, result|
          next unless scope.respond_to?(attribute)

          result[attribute] = scope.send(attribute)
        end
      {attributes: attributes.merge!(dynamic_attributes(scope))}
    end

    def dynamic_attributes(scope)
      return {} unless dynamic_attributes?

      filter(mapper.dynamic_attributes, dynamic: true)
        .each_with_object({}) do |(*attributes, block), result|
          attributes.each do |attr|
            value = scope.respond_to?(attr) ? scope.send(attr) : nil
            result[attr] = block.(value, scope, **options)
          end
        end
    end

    def document(scope)
      identifier(scope)
        .then { |doc| doc.merge!(attributes(scope), meta(scope), relationships(scope)) }
    end

    def identifier(scope)
      {type: type.to_s, id: id(scope).to_s}
    end

    def relationships(scope)
      return {} unless relationships?

      result = relationship.call(scope)
      return {} if result.empty?

      {relationships: result}
    end

    def meta(_scope = nil)
      return {} unless meta?

      {meta: mapper.meta}
    end

    def relationships?
      mapper.relationships.any?
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

    private

    def filter(attributes, dynamic: false)
      fieldset = options.fetch(:fields, {})[type.to_s]
      return attributes if fieldset.nil?
      return {} if fieldset.empty?
      return attributes.select { |a| fieldset.include?(a.to_s) } unless dynamic

      attributes.select { |(name, _block)| fieldset.include?(name.to_s) }
    end
  end
end
