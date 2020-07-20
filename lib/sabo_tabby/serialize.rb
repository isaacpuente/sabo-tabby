# frozen_string_literal: true

require "dry-initializer"
require "dry-core"
require "forwardable"
require "json/ext"
require "oj"
require "yajl"
require "concurrent"
require "sabo_tabby/document"

module SaboTabby
  class Serialize
    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants

    param :resource
    param :options, default: proc { EMPTY_HASH }

    def as_json
      #JSON.dump(as_hash)
      JSON.fast_generate(as_hash, create_additions: false, quirks_mode: true)
      #as_hash.to_json
      # Oj.dump(as_hash)
      # Yajl::Encoder.encode(as_hash)
    end

    def as_hash
      Document.new(resource, options).call
    end
  end
end
