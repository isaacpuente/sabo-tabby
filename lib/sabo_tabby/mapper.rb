# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "dry-core"
require "sabo_tabby/mapper/settings"
require "sabo_tabby/resource"
require "sabo_tabby/relationship"
require "sabo_tabby/helpers"

module SaboTabby
  module Mapper
    include Dry::Core::Constants

    def self.included(base)
      base.extend(Settings)
      base.extend(Dry::Initializer)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def initialize
        klass = self.class
        klass.settings.each do |key|
          param_name = key.to_s.split("_")[1..].join("_").to_sym
          name = param_name == :resource ? :name : param_name
          klass.param name, default: proc {
            case name
            when :type
              klass.send(key) || klass.send(:_resource)
            when :relationship, :attribute
              next
            else
              klass.send(key)
            end
          }
        end
        super()
      end

      def resource(mappers: {}, **options)
        return @resource if same_resource?(mappers, options)

        @resource = SaboTabby::Resource.new(self, options, mappers)
      end

      def compound_relationships(mapper = self)
        mapper.relationships
          .select { |_rel_name, rel_opts| rel_opts.fetch(:include, false) }
      end

      def attribute
        self.class.resource_attribute
      end

      def relationship
        self.class.resource_relationship
      end

      private

      def same_resource?(mappers, options)
        @resource && @resource.mappers == mappers && @resource.options == options
      end
    end

    module ClassMethods
      include Helpers

      def resource(name = Undefined)
        _setting(:resource, name).tap do
          next if name == Undefined

          dsl_methods.each { |method_name| send(method_name) }
          yield if block_given?
          container.register("mappers.#{name}", new) unless container.key?("mappers.#{name}")
        end
      end

      def links(**params, &block)
        # links do
        #   as_self ""
        #   related do |resource, request|
        #    
        #   end
        # end
        return yield if block

        if cumulative_setting?(:_links, params)
          _setting(:links, config.send(:_links).merge(params), {})
        else
          _setting(:links, params, {})
        end
      end

      def as_self(link = "", &block)
        links(**{self: link, block: block})
      end

      def related(link = "", &block)
        links(**{related: link, block: block})
      end

      def type(name = Undefined)
        _setting(:type, name)
      end

      def entity(name = Undefined)
        _setting(:entity, name)
      end

      def resource_identifier(id = :id)
        _setting(:resource_identifier, id, :id)
      end

      def attributes(*attrs)
        _setting(:attributes, attrs, [])
      end

      def attribute(*attrs, &block)
        attr = :dynamic_attributes

        value = attrs.empty? ? attrs : attrs << block
        return _setting(attr, value, []) unless cumulative_setting?("_#{attr}".to_sym, value)

        _setting(attr, config.send("_#{attr}".to_sym) << value, [])
      end

      alias_method :dynamic_attributes, :attribute

      def relationships(**params, &block)
        return yield if block

        if cumulative_setting?(:_relationships, params)
          _setting(:relationships, config.send(:_relationships).merge(params), {})
        else
          _setting(:relationships, params, {})
        end
      end

      def meta(**values)
        _setting(:meta, values, {})
      end

      def one(name, **opts)
        key = opts.fetch(:as, name).to_sym
        relationships(**{key => opts.merge(method: name, cardinality: :one)})
      end

      def many(name, **opts)
        key = opts.fetch(:as, name).to_sym
        relationships(**{key => opts.merge(method: name, cardinality: :many)})
      end

      def resource_relationship
        @relationship ||= SaboTabby::Relationship.new
      end

      def resource_attribute
        @attribute ||= SaboTabby::Attribute.new
      end

      private

      def dsl_methods
        %i(links type resource_identifier attributes dynamic_attributes meta relationships entity)
      end

      def inflector
        @inflector ||= SaboTabby::Container[:inflector]
      end

      def container
        SaboTabby::Container
      end
    end
  end
end
