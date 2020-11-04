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

      def call(scope)
        return {} if compound_paths.empty?

        compound_paths
          .each_with_object([]) { |path, compound| compound.concat(document(scope, path)) }
          .then { |compound| compound.any? ? {included: compound} : {} }
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
            parent_name = ""
            path.to_s.split(".").inject(scp) do |compound_scp, rel_name|
              next compound_scp if rel_name == resource_name(scope)

              compound_scope(compound_scp, rel_name, parent_name) do |cscope|
                doc.concat(cscope.flat_map { |csco| resource_document(csco, rel_name) })
                parent_name = rel_name
              end
            end
          end
        end
      end

      def compound_scope(scope, name, parent_name)
        Array(scope).flat_map do |sco|
          rel_opts = relationship_opts(name, scope_name(sco, parent_name).to_s)
          relationship_scope(sco, name, **rel_opts).tap do |relationship_scope|
            yield Array(relationship_scope) if block_given?
          end
        end
      end

      def relationship_scope(scope, name, **opts)
        return if scope.nil?

        if opts.any? && scope.respond_to?(opts[:method])
          scope.send(opts[:method])
        elsif scope.respond_to?(name)
          scope.send(name)
        end
      end

      def resource_document(scope, name)
        resource = resource(scope_name(scope), name)
        document_id = resource.document_id(scope)
        return [] if included_documents[document_id] || scope.nil?

        Array(scope)
          .map { |sc| resource.document(sc) }
          .tap { included_documents[document_id] = true }
      end

      def relationship_opts(name, scope_name)
        mapper(scope_name, name)
          .relationships
          .fetch(inflector.singularize(name).to_sym, {})
      end

      def resource(scope_name, name)
        mapper(scope_name, name).resource(mappers: mappers, **options)
      end

      def mapper(scope_name, name)
        mappers[scope_name] || mappers[name]
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
