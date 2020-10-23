# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "dry-core"
require "forwardable"
require "json/ext"
require "oj"
require "yajl"
require "simdjson"
require "concurrent"
require "sabo_tabby/document"
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
    param :document, default: proc { Document.new(resource, validated_options) }

    def as_json
      # JSON.dump(as_hash)
      # as_hash.to_json
      # @resource_json ||= Oj.dump(as_hash)
      # Yajl::Encoder.encode(as_hash)
      @resource_json ||= JSON.fast_generate(as_hash, create_additions: false, quirks_mode: true)
    end

    def as_hash
      @resource_hash ||= document.call
    end
  end
end
