# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "dry-core"
require "forwardable"
require "json/ext"
require "sabo_tabby/jsonapi/document"
require "sabo_tabby/json/document"
require "sabo_tabby/options_contract"

module SaboTabby
  class Serialize
    class OptionsError < StandardError; end

    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants

    param :resource
    param :options, default: proc { EMPTY_HASH }
    param :validated_options, default: proc {
      validation = OptionsContract.new.(options)
      raise OptionsError, validation.errors.to_h if validation.failure?

      validation.to_h
    }
    param :jsonapi_document, default: proc { SaboTabby::JSONAPI::Document.new(resource, validated_options) }
    param :json_document, default: proc { SaboTabby::JSON::Document.new(resource, validated_options) }

    def as_json(type: :jsonapi)
      as_hash(type: type).to_json
    end

    def as_hash(type: :jsonapi)
      send("#{type}_document").call
    end
  end
end
