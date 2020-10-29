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
      param :resources, default: proc { {} }
      param :mappers, default: proc { loader.mappers }
      param :compound_paths, default: proc { loader.compound_paths }
      param :compound_documents, default: proc { {} }

      def call(scope)
        return {} if compound_paths.empty?

        compound_paths
          .each_with_object([]) { |name, compound| compound.concat(document(scope, name)) }
          .then { |compound| compound.any? ? {included: compound} : {} }
      end

      private

      def scope_name(scope, name = "")
        Array(scope).last.then do |scp|
          next scp.class.send(:sabotabby_mapper) if scp.class.respond_to?(:sabotabby_mapper)

          name.empty? ? resource_name(scp) : name
        end
      end

      def document(scope, name)
        [].tap do |doc|
          Array(scope).flat_map do |scp|
            parent_name = ""
            name.to_s.split(".").inject(scp) do |compound_scp, rel_name|
              next compound_scp if rel_name == resource_name(scope)

              Array(compound_scp).flat_map do |iscope|
                scope_name = scope_name(iscope, parent_name).to_s
                rel_opts = relationship_opts(rel_name, scope_name)
                compound_scope(iscope, rel_name, **rel_opts) do |cscope|
                  doc.concat(
                    cscope.flat_map { |sc| resource_document(sc, rel_name, **rel_opts) }
                  )
                end
              end.tap { parent_name = rel_name }
            end
          end
        end
      end

      def compound_scope(scope, name, **opts)
        return if scope.nil?

        if opts.any? && scope.respond_to?(opts[:method])
          scope.send(opts[:method])
        elsif scope.respond_to?(name)
          scope.send(name)
        end.tap do |cscope|
          yield Array(cscope) if block_given?
        end
      end

      def resource_document(scope, name, **opts)
        resource = resource(scope, name)
        document_id = resource.document_id(scope)
        return [] if included_documents[document_id] || scope.nil?

        Array(scope)
          .map { |sc| resource.document(sc) }
          .tap { included_documents[document_id] = true }
      end

      def relationship_opts(name, scope_name)
        (mappers[scope_name] || mappers[name])
          .relationships
          .fetch(inflector.singularize(name).to_sym, {})
      end

      def resource(scope, name)
        (mappers[scope_name(scope)] || mappers[name]).resource(mappers: mappers, **options)
      end

      def container
        SaboTabby::Container
      end

      def inflector
        @inflector ||= container[:inflector]
      end
    end
  end
end
