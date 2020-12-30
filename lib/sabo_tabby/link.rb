# frozen_string_literal: true

# auto_register: false

require "dry-core"
require "dry-initializer"
require "sabo_tabby/helpers"

module SaboTabby
  class Link
    include Dry::Core::Constants
    extend Dry::Initializer
    include Helpers

    param :resource
    param :mapper, default: proc { resource.mapper }
    param :options, default: proc { resource.options }
    param :url, default: proc { options.fetch(:url, "") }

    def for_resource(scope)
      return {} unless resource_links?

      build_links(scope, mapper.links, :resource_link)
    end

    def for_relationship(scope, **settings)
      return {} unless relationship_links?(settings)

      build_links(scope, settings[:links], :relationship_link)
    end

    private

    def build_links(scope, links, method)
      links.each_with_object({}) do |(type, (value, block)), result|
        link = send(method, scope, value, &block)
        next if link.nil? || link.empty?

        result[type.to_s] = link
      end
    end

    def resource_links?
      mapper.respond_to?(:links) && mapper.links.any?
    end

    def relationship_links?(settings)
      settings[:links] &&
        settings[:links].any? &&
        settings[:links].none? { |_, v| v.empty? }
    end

    def resource_link(scope, name, &block)
      name = name == Undefined ? inflector.pluralize(mapper.name) : name
      if block
        yield url, name, scope
      else
        "#{url}/#{name}/#{scope.send(mapper.resource_identifier)}"
      end
    end

    def relationship_link(scope, name, &block)
      return "" if name.nil? || name.empty? 

      if block
        yield(url, name || Undefined, scope)
      elsif name.match?(/%{resource_link}/)
        name
          .gsub(/%{resource_link}/, resource_link(scope, Undefined, &block))
      else
        name
          .gsub(/%{resource_name}/, mapper.name.to_s)
          .gsub(/%resource_p_name}/, inflector.pluralize(mapper.name))
          .gsub(/%{resource_id}/, scope.send(mapper.resource_identifier).to_s)
          .then { |name| "#{url}/#{name}" }
      end
    end

    def inflector
      @inflector ||= SaboTabby::Container[:inflector]
    end
  end
end
