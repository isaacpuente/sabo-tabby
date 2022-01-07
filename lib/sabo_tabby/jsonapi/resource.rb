# frozen_string_literal: true

require "dry-initializer"
require "dry-core"
require "forwardable"
require "sabo_tabby/jsonapi/attribute"
require "sabo_tabby/jsonapi/relationship"
require "sabo_tabby/jsonapi/link"
require "sabo_tabby/helpers"

module SaboTabby
  module JSONAPI
    class Resource
      extend Dry::Initializer
      extend Forwardable
      include Helpers
      include Dry::Core::Constants

      def_delegators :mapper, :name, :type, :meta

      param :mapper
      param :options, default: proc { EMPTY_HASH }
      param :mappers, default: proc { {name.to_s => mapper} }
      param :attribute, default: proc { SaboTabby::JSONAPI::Attribute.new(self) }
      param :relationship, default: proc { SaboTabby::JSONAPI::Relationship.new(self) }
      param :link, default: proc { SaboTabby::JSONAPI::Link.new(self) }

      def id(scope)
        return scope if scope.is_a?(Integer)
        return EMPTY_STRING unless scope.respond_to?(mapper.resource_identifier)

        scope.send(mapper.resource_identifier)
      end

      def document(scope, **scope_settings)
        identifier(scope)
          .then do |doc|
            doc.merge!(
              attributes(scope),
              meta(scope),
              relationships(scope, **scope_settings),
              links(scope)
            )
          end
      end

      def identifier(scope)
        {type: type, id: id(scope).to_s}
      end

      def attributes(scope)
        attribute
          .call(scope)
          .then { |result| result.any? ? {attributes: result} : EMPTY_HASH }
      end

      def relationships(scope, **scope_settings)
        relationship
          .call(scope, **scope_settings)
          .then { |result| result.any? ? {relationships: result} : EMPTY_HASH }
      end

      def meta(scope)
        return {} unless meta?

        values, block = mapper.meta
        bresult = block ? block.(scope, **options) : EMPTY_HASH
        {meta: values.merge(bresult)} #.tap { |hmm| byebug }
      end

      def links(scope)
        link
          .for_resource(scope)
          .then { |result| result.any? ? {links: result} : EMPTY_HASH }
      end

      def meta?
        mapper.meta.first.any? || mapper.meta.last
      end

      def document_id(scope)
        "#{type}_#{id(scope)}"
      end
    end
  end
end
