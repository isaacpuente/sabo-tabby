# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Attribute
    extend Dry::Initializer

    param :resource
    param :mapper, default: proc { resource.mapper }
    param :options, default: proc { resource.options }

    def call(scope)
      return {} unless attributes? || dynamic_attributes?

      attributes(scope).merge!(dynamic_attributes(scope))
    end

    def attributes(scope)
      return {} unless attributes?

      filter(mapper.attributes)
        .each_with_object({}) do |attribute, result|
          next unless scope.respond_to?(attribute)

          result[attribute] = scope.send(attribute)
        end
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

    def attributes?
      mapper.attributes.any?
    end

    def dynamic_attributes?
      mapper.respond_to?(:dynamic_attributes) && mapper.dynamic_attributes.any?
    end

    def filter(attributes, dynamic: false)
      fieldset = options.fetch(:fields, {})[resource.type.to_s]
      return attributes if fieldset.nil?
      return {} if fieldset.empty?
      return attributes.select { |a| fieldset.include?(a.to_s) } unless dynamic

      attributes.select { |(name, _block)| fieldset.include?(name.to_s) }
    end
  end
end
