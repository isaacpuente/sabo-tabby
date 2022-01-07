# frozen_string_literal: true

require "dry-initializer"
require "dry-core"
require "sabo_tabby/helpers"

module SaboTabby
  module JSONAPI
    class Attribute
      extend Dry::Initializer
      include Dry::Core::Constants
      include Helpers

      param :resource
      param :mapper, default: proc { resource.mapper }
      param :options, default: proc { resource.options }

      def call(scope)
        return EMPTY_HASH unless attributes? || dynamic_attributes?

        attributes(scope).merge!(dynamic_attributes(scope))
      end

      def attributes(scope)
        return EMPTY_HASH unless attributes?

        filter
          .each_with_object({}) do |(name, key_name), result|
            next unless scope.respond_to?(name)

            result[key_name] = scope.send(name)
          end
      end

      def dynamic_attributes(scope)
        return EMPTY_HASH unless dynamic_attributes?

        filter(dynamic: true)
          .each_with_object({}) do |(name, (key_name, block)), result|
            value = scope.respond_to?(name) ? scope.send(name) : nil
            next if scope.is_a?(Numeric)

            result[key_name] = block.(value, scope, **options)
          end
      end

      def attributes?
        mapper.attributes.any?
      end

      def dynamic_attributes?
        mapper.respond_to?(:dynamic_attributes) && mapper.dynamic_attributes.any?
      end

      def filter(dynamic: false)
        attributes = dynamic ? mapper.dynamic_attributes : mapper.attributes
        fieldset = options.fetch(:fields, {})[mapper.type.to_s]
        return attributes if fieldset.nil?
        return EMPTY_HASH if fieldset.empty?
        return attributes.select { |name, _| fieldset.include?(name.to_s) } unless dynamic

        attributes.select { |name, _| fieldset.include?(name.to_s) }
      end
    end
  end
end
