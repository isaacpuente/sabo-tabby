# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"
require "sabo_tabby/attribute"
require "sabo_tabby/relationship"

module SaboTabby
  class Resource
    extend Dry::Initializer
    extend Forwardable

    def_delegators :mapper, :name, :type, :link, :meta

    param :mapper
    param :options, default: proc { EMPTY_HASH }
    param :mappers, default: proc { {name.to_s => mapper} }
    param :attribute, default: proc { mapper.attribute }
    param :relationship, default: proc { mapper.relationship }

    def id(scope)
      return scope if scope.is_a?(Integer)
      return "" unless scope.respond_to?(mapper.resource_identifier)

      scope.send(mapper.resource_identifier)
    end

    def document(scope)
      identifier(scope)
        .then { |doc| doc.merge!(attributes(scope), meta(scope), relationships(scope)) }
    end

    def identifier(scope)
      {type: type.to_s, id: id(scope).to_s}
    end

    def attributes(scope)
      attribute
        .call(mapper, scope, **options)
        .then { |result| result.empty? ? {} : {attributes: result} }
    end

    def relationships(scope)
      relationship
        .call(mapper, scope, **mappers)
        .then { |result| result.empty? ? {} : {relationships: result} }
    end

    def meta(_scope = nil)
      return {} unless meta?

      {meta: mapper.meta}
    end

    def meta?
      mapper.meta.any?
    end

    def document_id(scope)
      "#{type}_#{id(scope)}"
    end
  end
end
