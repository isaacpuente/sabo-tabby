# frozen_string_literal: true

require "dry-initializer"

module SaboTabby
  module Mapper
    class Loader
      extend Dry::Initializer

      param :options, default: proc { EMPTY_HASH }

      def self.for(name, **options)
        new(options).call(name)
      end

      def call(name)
        return error_mappers(name) if error?(name)

        container["mappers.#{name}"]
          .with(**options)
          .then do |resource_mapper|
            {name => resource_mapper}
              .merge!(relationship_mappers(resource_mapper), compound_mappers)
          end
      end

      private

      def relationship_mappers(mapper)
        mapper
          .relationships
          .one
          .merge(mapper.relationships.many)
          .each_with_object({}) do |(name, opts), mprs|
            rel_name = inflector.singularize(opts.fetch(:as, name))
            mprs[rel_name] ||= container["mappers.#{rel_name}"].with(**options)
          end
      end

      def compound_mappers
        options
          .fetch(:include, [])
          .each_with_object({}) do |name, mprs|
            name.to_s.split(".").map do |n|
              m_name = inflector.singularize(n)
              mprs[m_name] ||= container["mappers.#{m_name}"].with(**options)
              mprs.update(relationship_mappers(mprs[m_name]))
            end
          end
      end

      def error_mappers(name)
        err_mappers = container
          .keys
          .select { |k| k.include?("mappers.errors") && k.split(".").last == name }
        mapper_name = err_mappers.empty? ? "mappers.errors.standard_error" : err_mappers.first
        {name => container[mapper_name]}
      end

      def error?(name)
        options[:error] || String(name).include?("error")
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
