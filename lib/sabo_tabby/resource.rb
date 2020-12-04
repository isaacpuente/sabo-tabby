# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"
require "sabo_tabby/attribute"
require "sabo_tabby/relationship"
require "sabo_tabby/helpers"

module SaboTabby
  class Resource
    extend Dry::Initializer
    extend Forwardable
    include Helpers

    def_delegators :mapper, :name, :type, :meta

    param :mapper
    param :options, default: proc { EMPTY_HASH }
    param :mappers, default: proc { {name.to_s => mapper} }
    param :attribute, default: proc { SaboTabby::Attribute.new(self) }
    param :relationship, default: proc { SaboTabby::Relationship.new(self) }
    param :link, default: proc { SaboTabby::Link.new(self) }

    def id(scope)
      return scope if scope.is_a?(Integer)
      return "" unless scope.respond_to?(mapper.resource_identifier)

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
      {"type" => type, "id" => id(scope).to_s}
    end

    def attributes(scope)
      attribute
        .call(scope)
        .then { |result| result.any? ? {"attributes" => result} : {} }
    end

    def relationships(scope, **scope_settings)
      relationship
        .call(scope, **scope_settings)
        .then { |result| result.any? ? {"relationships" => result} : {} }
    end

    def meta(_scope = nil)
      return {} unless meta?

      {"meta" => mapper.meta}
    end

    def links(scope)
      link
        .call(scope)
        .then { |result| result.any? ? {"links" => result} : {} }
    end

    def meta?
      mapper.meta.any?
    end

    def document_id(scope)
      "#{type}_#{id(scope)}"
    end
  end
end
