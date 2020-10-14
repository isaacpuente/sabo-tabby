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
      #JSON.dump(as_hash)
      #
      # p "*********************************"

      # p Benchmark.bm { |x|
      #   x.report("as_hash") { @resource_hash = as_hash }
      # }
      # p Benchmark.bm { |x|
      #   x.report("as_json") { @resource_json = JSON.fast_generate(@resource_hash, create_additions: false, quirks_mode: true) }
      # }
      @resource_json ||= JSON.fast_generate(as_hash, create_additions: false, quirks_mode: true)
      #as_hash.to_json
      # @resource_json ||= Oj.dump(as_hash)
      # Yajl::Encoder.encode(as_hash)
    end

    def as_hash
      @resource_hash ||= document.call # .tap { |hmm| byebug }
    end
  end
end
