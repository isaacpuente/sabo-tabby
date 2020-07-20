# frozen_string_literal: true

require "dry-initializer"
require "forwardable"
require "sabo_tabby/document/compound"
require "sabo_tabby/mapper/loader"
require "sabo_tabby/pagination"

module SaboTabby
  class Document
    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants

    param :resource
    param :options, default: proc { EMPTY_HASH }
    param :mappers, default: proc { Mapper::Loader.for(resource_name, **options) }

    def_delegator :mapper_resource, :document

    def call
      return error_document if error?

      resource_document
    end

    def resource_name
      @resource_name ||= (collection? ? resource.first : resource).then do |res|
        res
          .class
          .name
          .split("::")
          .last
          .split(/(?=\p{upper}\p{lower}+)/)
          .map(&:downcase)
          .join("_")
      end
    end

    def mapper_resource
      @mapper_resource ||= mappers[resource_name].resource.with(mappers: mappers)
    end

    def meta
      return {} unless options[:meta]

      {meta: options[:meta]}
    end

    def compound_document
      return {} unless options[:include]

      @compound ||= container["document.compound"].with(mappers, options).(resource)
    end

    def error?
      options.fetch(:error, false) || resource_name.include?("error")
    end

    def collection?
      resource.is_a?(Array) || paginated?
    end

    def paginated?
      options.key?(:pager)
    end

    private

    def error_document
      {errors: Array(resource).map { |r| document(r) }}
    end

    def resource_document
      data = collection? ? resource.map { |r| document(r) } : document(resource)
      {data: data}.merge!(compound_document, paginate(meta))
    end

    def paginate(meta)
      return meta unless paginated?

      @pagination = container["pagination"]
        .with(mappers, options)
        .then do |pagination|
          {meta: meta.fetch(:meta, {}).merge(pagination.meta), links: pagination.links}
        end
    end

    def container
      SaboTabby::Container
    end
  end
end
