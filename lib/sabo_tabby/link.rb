# frozen_string_literal: true

# auto_register: false

require "dry-core"
require "dry-initializer"

module SaboTabby
  class Link
    include Dry::Core::Constants
    extend Dry::Initializer

    param :resource
    param :mapper, default: proc { resource.mapper }
    param :options, default: proc { resource.options }
    param :mappers, default: proc { resource.mappers }

    def call(scope, relationship_links: false)
      return {} unless links?

      url = options.fetch(:url, "http://localhost")

      mapper.links.each_with_object({}) do |(type, (name, block)), result|
        link = build_resource_links(scope, name, url, &block)
        next if link.nil? || link.empty?

        result[type] = link
      end
    end

    private

    def links?
      mapper.respond_to?(:links) && mapper.links.any?
    end

    def build_resource_links(scope, name, url, &block)
      name = name == Undefined ? inflector.pluralize(mapper.name) : name
      if block
        yield url, name, scope
      else
        "#{url}/#{name}/#{scope.send(mapper.resource_identifier)}"
      end
    end

    def inflector
      @inflector ||= SaboTabby::Container[:inflector]
    end
  end
end
