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
      param :mappers, default: proc {
        {inflector.singularize(resource_name) => resource_mapper}.tap do |mprs|
          next if error?

          mprs.merge!(relationship_mappers)
        end
      }

      param :scope_settings, default: proc {
        next {} if error?

        _scope_settings(resource, mapper)
      }

      param :compound_paths, default: proc {
        next [] if error?

        if options.fetch(:include, false)
          options[:include] == %w(none) ? [] : options[:include]
        else
          _compound_paths(scope_settings)
        end.tap { |cp| mappers.merge!(compound_mappers(cp)) }
      }

      def mapper
        return error_mapper(resource_name) if error?

        container["mappers.#{resource_name}"]
      end

      def error?
        options[:error] || String(resource_name).downcase.include?("error")
      end

      private

      def relationship_mappers(mapper = resource_mapper)
        mapper.relationships
          .each_with_object({}) do |(name, opts), mprs|
            rel_name = inflector.singularize(opts.fetch(:as, name))
            mprs[rel_name] ||= container["mappers.#{rel_name}"]
          end
      end

      def compound_mappers(paths)
        @compound_mappers ||= paths
          .each_with_object({}) do |name, mprs|
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

      def _compound_paths(c_resources)
        c_resources
          .each_with_object([]) do |(name, relationships), result|
            next unless relationships.fetch(:include, false)
            next result << name.to_s if relationships.none? { |_k, v| v.is_a?(Hash) }

            Array(_compound_paths(relationships.select { |_k, v| v.is_a?(Hash) }))
              .then { |path| path.map { |p| result << "#{name}.#{p}" } }
          end
      end

      def scope_message?(scope, message)
        return false if message.nil?

        Array(scope).any? { |s| s.respond_to?(message) }
      end

      def scope_message(scope, message)
        return nil if message.nil?

        Array(scope)
          .find { |s|
            s.respond_to?(message) &&
              (s.send(message).is_a?(Array) ? s.send(message).any? : true)
          }&.send(message)
      end

      def scope_name(scope, message)
        return nil if message.nil?

        if Array(scope).any? { |s| s.respond_to?(message) && !skip_setting?(s.send(message)) }
          message
        elsif id_object?(scope, message)
          "#{message}_id"
        end
      end

      def id_object?(scope, message)
        Array(scope).any? { |s|
          s.respond_to?("#{message}_id") && !skip_setting?(s.send("#{message}_id"))
        }
      end

      def _scope_settings(scope, resource_mapper, depth = 0)
        resource_mapper.relationships.each_with_object({}) do |(name, opts), result|
          rel_scope_name = scope_name(scope, opts[:method])
          rel_name = opts.fetch(:as, name)
          mapper_name = inflector.singularize(rel_name)
          mapper = mappers[mapper_name] || container["mappers.#{mapper_name}"]

          next if depth > options.fetch(:max_depth, 1) || rel_scope_name.nil? || mapper.nil?

          result[rel_name] = setting_entry(scope, mapper, rel_scope_name, depth, **opts)
        end
      end

      def skip_setting?(scope)
        scope.nil? || (scope.is_a?(Array) && scope.empty?)
      end

      def setting_entry(scope, mapper, scope_name, depth, **relationship_opts)
        relationship_opts
          .merge(
            {
              scope: scope_name,
              type: relationship_opts.fetch(:type, mapper.type),
              identifier: mapper.resource_identifier
            },
            _scope_settings(
              scope_message(scope, scope_name),
              mapper,
              depth + 1
            )
          )
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
