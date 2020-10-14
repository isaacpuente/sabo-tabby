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
      param :mappers, default: proc { loader.compound_mappers }
      param :compound_paths, default: proc { loader.compound_paths }

      def call(scope)
        return {} if compound_paths.empty?

        compound_paths
          .each_with_object([]) { |name, compound| document(compound, name, scope) }
          .then { |compound| compound.any? ? {included: compound} : {} }
      end

      private

      def scope_name(scope)
        Array(scope).last.then do |scp|
          next resource_name(scp) unless scp.class.respond_to?(:sabotabby_mapper)

          scp.class.send(:sabotabby_mapper)
        end
      end

      def document(compound, name, scope)
        Array(scope).flat_map do |scp|
          name.to_s.split(".").inject(scp) do |compound_scp, rel_name|
            next compound_scp if rel_name == resource_name(scope)

            scope_document(compound, rel_name, compound_scp)
          end
        end
      end

      def scope_document(compound, rel_name, scope)
        Array(scope).flat_map do |iscope|
          scope_name = scope_name(iscope).to_s
          rel_opts = relationship_opts(rel_name, scope_name)
          compound_scope(rel_name, rel_opts, iscope).tap do |cscope|
            compound.concat(Array(cscope).flat_map { |s| resource_document(rel_name, s) }.compact)
          end
        rescue => e
          byebug
        end
      end

      def compound_scope(name, rel_opts, scope)
        return nil if scope.nil?

        if rel_opts.any? && scope.respond_to?(rel_opts[:method])
          scope.send(rel_opts[:method])
        elsif scope.respond_to?(name)
          scope.send(name)
        end
      end

      def resource_document(name, scope)
        scope_name = scope_name(scope)
        resources[scope_name] ||= resource(name, scope_name)
        return nil if included_documents[resources[scope_name].document_id(scope)] || scope.nil?

        # byebug if name == "user"
        # (mappers[scope_name] || mappers[name]).resource(mappers: mappers, **options)
        Array(scope)
          .map { |sc| resources[scope_name].document(sc) }
          .tap { included_documents[resources[scope_name].document_id(scope)] = true }
      end

      def relationship_opts(name, scope_name)
        (mappers[scope_name] || mappers[name])
          .relationships
          .then do |mapper_rels|
            mapper_rels.one.merge(mapper_rels.many).fetch(inflector.singularize(name).to_sym, {})
          end
      end

      def resource(name, scope_name)
        (mappers[scope_name] || mappers[name]).resource(mappers: mappers, **options)
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
