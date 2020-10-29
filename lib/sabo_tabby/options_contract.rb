# frozen_string_literal: true

require "dry/validation"

module Types
  include Dry::Types()

  QueryStringArray = Types.Constructor(::Array) do |value|
    next value if value.is_a?(::Array)

    value.split(",")
  end
end
module SaboTabby
  class OptionsContract < Dry::Validation::Contract
    params do
      optional(:include).value(Types::QueryStringArray)
      optional(:fields).type(Types::Hash.map(Types::String, Types::QueryStringArray))
      optional(:url).filled(:string)
      optional(:meta).hash
      optional(:pager_klass).filled(:string)
      optional(:pager)
      optional(:auto_compound).filled(:bool)
      optional(:error).filled(:bool)
    end
  end
end
