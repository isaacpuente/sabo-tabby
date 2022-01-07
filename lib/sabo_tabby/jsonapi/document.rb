# frozen_string_literal: true

require "sabo_tabby/document"
require "sabo_tabby/jsonapi/compound_document"

module SaboTabby
  module JSONAPI
    class Document < SaboTabby::Document
      def call
        return error_document if error?

        resource_document
      end

      def meta
        return {} unless options[:meta]

        {meta: options[:meta]}
      end

      def links
        return {} if options.fetch(:skip_root_links, false) || options[:url].nil?

        {links: {self: options[:url]}}
      end

      def compound_document
        return EMPTY_HASH unless compound_document?

        @compound ||= SaboTabby::JSONAPI::CompoundDocument.new(loader, options).(resource)
      end

      private

      def resource_document
        settings = loader.scope_settings
        if collection?
          {data: resource.map { |r| document(r, **settings) }}
        else
          {data: document(resource, **settings)}
        end.merge!(compound_document, paginate(meta, links))
      end
    end
  end
end
