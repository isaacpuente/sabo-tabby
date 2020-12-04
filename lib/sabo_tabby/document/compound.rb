# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "sabo_tabby/helpers"

module SaboTabby
  class Document
    class Compound
      extend Dry::Initializer
      include Dry::Core::Constants
      include Helpers

      param :loader
      param :options, default: proc { EMPTY_HASH }
      param :included_documents, default: proc { {} }
      param :mappers, default: proc { loader.mappers }
      param :compound_paths, default: proc { loader.compound_paths }

      def call(scope)
        return {} if compound_paths.empty?

        compound_paths
          .each_with_object([]) { |path, compound| compound.concat(document(scope, path)) }
          .then { |compound| compound.any? ? {"included" => compound} : {} }
      end

      private

      def scope_name(scope, name = "")
        Array(scope).last.then do |scp|
          next scp.class.send(:sabotabby_mapper) if scp.class.respond_to?(:sabotabby_mapper)

          name.empty? ? resource_name(scp) : name
        end
      end

      def document(scope, path)
        [].tap do |doc|
          Array(scope).flat_map do |scp|
            traversed_path = []
            path.to_s.split(".").inject(scp) do |compound_scp, rel_name|
              next compound_scp if rel_name == resource_name(scope)

              settings = scope_settings(traversed_path, rel_name.to_sym)
              compound_scope(compound_scp, **settings).tap do |cscope|
                doc.concat(cscope.flat_map { |csco| resource_document(csco, rel_name, **settings) })
                traversed_path << rel_name.to_sym
              end
            end
          end
        end
      end

      def scope_settings(path, name)
        return loader.scope_settings.fetch(name, {}) if path.empty?

        loader.scope_settings.dig(*path.uniq << name) || {}
      end

      def compound_scope(scope, **settings)
        return [] if settings.empty?

        Array(scope).flat_map { |sco| sco.send(settings[:scope]) }
      end

      def resource_document(scope, name, **settings)
        resource = resource(scope_name(scope), name)
        document_id = resource.document_id(scope)
        return [] if included_documents[document_id] || scope.nil?

        Array(scope)
          .map { |sc| resource.document(sc, **settings) }
          .tap { included_documents[document_id] = true }
      end

      def resource(scope_name, name)
        mapper(scope_name, name).resource(mappers: mappers, **options)
      end

      def mapper(scope_name, name)
        mappers[scope_name] || mappers[name]
      end
    end
  end
end
