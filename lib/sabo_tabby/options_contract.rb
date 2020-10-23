# frozen_string_literal: true

require "dry/validation"

module SaboTabby
  class OptionsContract < Dry::Validation::Contract
    params do
      optional(:include).array(:str?)
      optional(:fields).hash
      optional(:url).filled(:string)
      optional(:meta).hash
      optional(:pager_klass).filled(:string)
      optional(:pager)
      optional(:auto_compound).filled(:bool)
      optional(:error).filled(:bool)
    end
  end
end
