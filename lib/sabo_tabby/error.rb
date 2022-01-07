# frozen_string_literal: true

# auto_register: false

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
      origins = Array(mapper.origin.(scope))
      detail(scope).map.with_index { |error, index|
        {
          status: String(status(scope)),
          title: title(scope),
          detail: error
        }.merge!(
          code_value(scope),
          source(origins[index])
        )
      }
    end

    %i(title status code).each do |name|
      define_method name do |scope|
        return mapper.send(name) unless scope.respond_to?(name)

        scope.send(name)
      end
    end

    def detail(scope)
      Array(mapper.detail.(scope))
    end

    def source(origin)
      return EMPTY_HASH if origin.nil?

      {source: {pointer: origin}}
    end

    def code_value(scope)
      value = code(scope)
      return {code: EMPTY_STRING} if value.nil?

      {code: String(value)}
    end
  end
end
