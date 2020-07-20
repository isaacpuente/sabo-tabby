# frozen_string_literal: true

require "dry-initializer"

module SaboTabby
  class Document
    class Compound
      extend Dry::Initializer
      include Dry::Core::Constants

      param :mappers, default: proc { {} }
      param :options, default: proc { EMPTY_HASH }
      param :included_documents, default: proc { {} }
      param :resources, default: proc { {} }

      def call(scope)
        return {} unless options[:include]

        options[:include]
          .each_with_object([]) { |name, compound| document(compound, name, scope) }
          .then { |compound| compound.any? ? {included: compound} : {} }
      end

      def with(mappers, options)
        self.class.new(mappers, options)
      end

      private

      def scope_name(scope)
        (scope.is_a?(Array) ? scope.first : scope).then do |scp|
          if scope.class.respond_to?(:sabotabby_mapper)
            scope.class.sabotabby_mapper.to_s
          else
            scp.class.name.split("::").last
              .split(/(?=\p{upper}\p{lower}+)/).map(&:downcase).join("_")
          end
        end
      end

      def document(compound, name, scope)
        Array(scope).flat_map do |scp|
          name.to_s.split(".").inject(scp) do |compound_scp, rel_name|
            scope_document(compound, rel_name, compound_scp)
          end
        end
      end

      def scope_document(compound, name, scope)
        Array(scope).flat_map do |iscope|
          compound_scope(name, iscope).tap do |cscope|
            next if included_documents[cscope.hash]

            compound.concat(Array(cscope).flat_map { |s| resource_document(s) })
            included_documents[cscope.hash] = 1
          end
        end
      end

      def compound_scope(name, res = scope)
        scope_name = scope_name(res)
        if res.respond_to?(name)
          res.send(name)
        elsif (rel_opts = relationship_opts(name, scope_name))
          if rel_opts[:method]
            res.send(rel_opts[:method])
          end
        elsif res.respond_to?("#{name}_id")
          res.send("#{name}_id")
        end
      end

      def resource_document(scp = scope)
        resources[scope_name(scp)] ||=
          mappers[scope_name(scp)].resource.with(mappers: mappers, **options)
        Array(scp).map { |sc| resources[scope_name(scp)].document(sc) }
      end

      def relationship_opts(name, scope_name)
        mappers[scope_name]
          .relationships
          .then do |mapper_rels|
            mapper_rels.one.merge(mapper_rels.many).fetch(inflector.singularize(name).to_sym, {})
          end
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
