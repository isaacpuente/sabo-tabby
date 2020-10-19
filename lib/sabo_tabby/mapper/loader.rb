# frozen_string_literal: true

# auto_register: false

require "dry-initializer"

module SaboTabby
  module Mapper
    class Loader
      extend Dry::Initializer

      param :resource
      param :resource_name
      param :options, default: proc { EMPTY_HASH }
      param :resource_mapper, default: proc { mapper }
      param :mappers, default: proc { {} }

      def init_mappers(compound: false)
        mappers
          .merge!(resource_name => resource_mapper)
          .tap do
            next if error?

            relationship_mappers
            compound_mappers if compound
          end
      end

      def compound_paths
        @compound_paths ||= if options.fetch(:include, false)
                              options[:include] == :none ? [] : options[:include]
                            else
                              compound_resources(resource, resource_mapper)
                                .then { |c_resources| _compound_paths(c_resources) }
                            end
      end

      def mapper
        return error_mapper(resource_name) if error?

        container["mappers.#{resource_name}"]
      end

      def relationship_mappers(mapper = resource_mapper)
        mapper
          .relationships
          .one
          .merge(mapper.relationships.many)
          .each_with_object(mappers) do |(name, opts), mprs|
            rel_name = inflector.singularize(opts.fetch(:as, name))
            mprs[rel_name] ||= container["mappers.#{rel_name}"]
          end
      end

      def compound_mappers
        @compound_mappers ||= compound_paths
          .each_with_object(mappers) do |name, mprs|
          name.to_s.split(".").map do |n|
            m_name = inflector.singularize(n)
            mprs[m_name] ||= container["mappers.#{m_name}"]
            mprs.merge!(relationship_mappers(mprs[m_name]))
          end
        end
      end

      def error_mapper(name)
        container
          .keys
          .select { |k| k.include?("mappers.errors") && k.split(".").last == name }
          .then { |em| em.empty? ? "mappers.errors.standard_error" : em.first }
          .then { |mapper_name| container[mapper_name] }
      end

      def error?
        options[:error] || String(resource_name).include?("error")
      end

      private

      def compound_resources(resource, resource_mapper, included_keys = [resource_mapper.name])
        resource_mapper.compound_relationships.each_with_object({}) do |(name, opts), result|
          next unless message?(resource, opts[:method])

          included_keys.push(name)
          n_resource = message(resource, opts[:method])

          result[name] = (mappers[name.to_s] ||= container["mappers.#{name}"])
            .compound_relationships.each_with_object({}) do |(c_name, c_opts), c_result|
              next unless message?(n_resource, c_opts[:method])

              c_result[c_name] = compound_resources(
                message(n_resource, c_opts[:method]),
                mappers[c_name.to_s] ||= container["mappers.#{c_name}"],
                included_keys << c_name
              )
            end
        end
      end

      def _compound_paths(c_resources)
        c_resources
          .each_with_object([]) do |(name, relationships), result|
            next result << name.to_s if relationships.empty?

            result.concat(
              relationships.each_with_object([]) do |(rel_name, rels), sub_result|
                next sub_result << "#{name}.#{rel_name}" if rels.empty?

                Array(_compound_paths(rels))
                  .then { |path| path.map { |p| sub_result << "#{name}.#{rel_name}.#{p}" } }
              end
            )
          end
      end

      def message(resource, message)
        return nil if message.nil?

        Array(resource)
          .find { |r| r.respond_to?(message) }
          &.send(message)
      end

      def message?(resource, message)
        return false if message.nil?

        Array(resource).any? { |r| r.respond_to?(message) }
      end

      def container
        SaboTabby::Container
      end

      def inflector
        @inflector ||= SaboTabby::Container[:inflector]
      end
    end
  end
end
