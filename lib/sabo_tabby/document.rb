# frozen_string_literal: true

require "dry-initializer"
require "sabo_tabby/pagination"
require "sabo_tabby/mapper/loader"
require "sabo_tabby/helpers"
require "forwardable"

module SaboTabby
  class Document
    extend Dry::Initializer
    include Dry::Core::Constants
    include Helpers
    extend Forwardable

    def_delegator :mapper_resource, :document

    param :resource
    param :options, default: proc { _options }
    param :loader, default: proc { Mapper::Loader.new(resource, **options) }
    param :mappers, default: proc { loader.mappers }

    def name
      @name ||= resource_name(resource)
    end

    def mapper_resource
      @mapper_resource ||= mappers[name].resource(mappers: mappers, **options)
    end

    def error?
      options.fetch(:error, false) || String(name).include?("error")
    end

    def collection?
      resource.is_a?(Array) || paginated?
    end

    def paginated?
      !options.fetch(:pager, nil).nil?
    end

    def compound_document?
      options.fetch(:auto_compound, false) || options.fetch(:include, false)
    end

    protected

    def error_document
      {errors: Array(resource).flat_map { |r| document(r) }}
    end

    def paginate(meta, links)
      return meta.merge!(links) unless paginated?

      @pagination = SaboTabby::Pagination.new(mappers, options)
        .then do |pagination|
          {
            meta: meta.fetch(:meta, {}).merge!(pagination.meta),
            links: links.fetch(:links, {}).merge!(pagination.links)
          }
        end
    end

    def _options
      {
        error: false,
        auto_compound: false,
        pager: nil,
        include: EMPTY_ARRAY
      }
    end
  end
end
