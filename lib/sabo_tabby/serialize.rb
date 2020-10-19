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

module SaboTabby
  class Serialize
    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants

    param :resource
    param :options, default: proc { EMPTY_HASH }
    param :document, default: proc { Document.new(resource, options) }

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
