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
      optional(:skip_top_links).filled(:bool)
      optional(:meta).hash
      optional(:pager_klass).filled(:string)
      optional(:pager)
      optional(:auto_compound).filled(:bool)
      optional(:error).filled(:bool)
      optional(:max_depth).filled(:integer)
    end

    rule(:max_depth) do
      next if value.nil?

      key.failure("Maximum depth exceeded") if value > 10
      key.failure("Mininmum depth cannot be less than 1") if value < 1
    end
  end
end
