# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"
require "sabo_tabby/document/compound"
require "sabo_tabby/mapper/loader"
require "sabo_tabby/pagination"
require "sabo_tabby/helpers"
require "benchmark"

module SaboTabby
  class Document
    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants
    include Helpers

    param :resource
    param :options, default: proc { _options }
    param :loader, default: proc { Mapper::Loader.new(resource, name, **options) }
    param :mappers, default: proc { loader.mappers }

    def_delegator :mapper_resource, :document

    def call
      return error_document if error?

      resource_document
    end

    def name
      @name ||= resource_name(resource)
    end

    def mapper_resource
      @mapper_resource ||= mappers[name].resource(mappers: mappers, **options)
    end

    def meta
      return {} unless options[:meta]

      {meta: options[:meta]}
    end

    def links
      return {} unless options[:url]

      {links: {self: options[:url]}}
    end

    def compound_document
      return {} unless compound_document?

      @compound ||= SaboTabby::Document::Compound.new(loader, options).(resource)
    end

    def error?
      options.fetch(:error, false) || name.include?("error")
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

    private

    def error_document
      {errors: Array(resource).flat_map { |r| document(r) }}
    end

    def resource_document
      settings = loader.scope_settings
      if collection?
        {data: resource.map { |r| document(r, **settings) }}
      else
        {data: document(resource, **settings)}
      end.merge!(compound_document, paginate(meta, links))
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

    def container
      SaboTabby::Container
    end

    def _options
      {
        error: false,
        auto_compound: false,
        pager: nil,
        include: []
      }
    end
  end
end
