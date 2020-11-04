# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Attribute
    def call(mapper, scope, **options)
      return {} unless attributes?(mapper) || dynamic_attributes?(mapper)

      attributes(mapper, scope, **options)
        .merge!(dynamic_attributes(mapper, scope, **options))
    end

    def attributes(mapper, scope, **options)
      return {} unless attributes?(mapper)

      filter(mapper, **options)
        .each_with_object({}) do |attribute, result|
          next unless scope.respond_to?(attribute)

          result[attribute] = scope.send(attribute)
        end
    end

    def dynamic_attributes(mapper, scope, **options)
      return {} unless dynamic_attributes?(mapper)

      filter(mapper, dynamic: true, **options)
        .each_with_object({}) do |(*attributes, block), result|
          attributes.each do |attr|
            value = scope.respond_to?(attr) ? scope.send(attr) : nil
            result[attr] = block.(value, scope, **options)
          end
        end
    end

    def attributes?(mapper)
      mapper.attributes.any?
    end

    def dynamic_attributes?(mapper)
      mapper.respond_to?(:dynamic_attributes) && mapper.dynamic_attributes.any?
    end

    def filter(mapper, dynamic: false, **options)
      attributes = dynamic ? mapper.dynamic_attributes : mapper.attributes
      fieldset = options.fetch(:fields, {})[mapper.type.to_s]
      return attributes if fieldset.nil?
      return {} if fieldset.empty?
      return attributes.select { |a| fieldset.include?(a.to_s) } unless dynamic

      attributes.select { |(name, _block)| fieldset.include?(name.to_s) }
    end
  end
end
