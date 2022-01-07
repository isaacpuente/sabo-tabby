# frozen_string_literal: true

require "sabo_tabby/document"

module SaboTabby
  module JSON
    class Document < SaboTabby::Document
      def call
        {data: {id: resource.id, cat_id: resource.cat_id, name: resource.name}}
      end

      private

      def resource_document
        settings = loader.scope_settings
        return {data: document(resource, **settings)} unless collection?

        {data: resource.map { |r| document(r, **settings) }}
      end
    end
  end
end
