# frozen_string_literal: true

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Error
    extend Dry::Initializer
    extend Forwardable
    include Dry::Core::Constants

    def_delegator :mapper, :name

    param :mapper
    param :options, default: proc { EMPTY_HASH }
    param :mappers, default: proc { {name => mapper} }

    def document(scope)
      {status: String(status(scope)), title: title(scope), detail: detail(scope)}
        .merge(code_value(scope))
    end

    def with(mappers: {}, **opts)
      tap {
        @mappers = mappers if mappers.any?
        @options = opts
      }
    end

    %i(title status code).each do |name|
      define_method name do |scope|
        return mapper.send(name) unless scope.respond_to?(name)

        scope.send(name)
      end
    end

    def detail(scope)
      mapper.detail.(scope)
    end

    def source(value)
      return {} if value.nil? || value.empty?

      {source: {pointer: value}}
    end

    def code_value(scope)
      value = code(scope)
      return {code: ""} if value.nil?

      {code: String(value)}
    end
  end
end
