# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "dry-core"
require "sabo_tabby/mapper/settings"
require "sabo_tabby/jsonapi/resource"

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
        klass.param :name, default: proc { klass.resource }
        klass.param :links, default: proc { klass.links }
        klass.param :meta, default: proc { klass.meta }
        klass.param :resource_identifier, default: proc { klass.resource_identifier }
        klass.param :key_transformation, default: proc { _key_transformation }
        klass.param :attributes, default: proc { _attributes }
        klass.param :dynamic_attributes, default: proc { _dynamic_attributes }
        klass.param :key_name, default: proc { _key_name }
        klass.param :relationships, default: proc { _relationships }
        klass.param :type, default: proc { _type }
        super()
      end

      def resource(mappers: {}, **options)
        return @resource if same_resource?(mappers, options)

        @resource = SaboTabby::JSONAPI::Resource.new(self, options, mappers)
      end

      def container
        SaboTabby::Container
      end

      def inflector
        @inflector ||= container[:inflector]
      end

      private

      def same_resource?(mappers, options)
        @resource && @resource.mappers == mappers && @resource.options == options
      end

      def _attributes
        self.class.attributes.each_with_object({}) do |name, attrs|
          attrs[name] = inflector.send(key_transformation, name).to_sym
        end
      end

      def _dynamic_attributes
        self.class.dynamic_attributes.each_with_object({}) do |(*names, block), attrs|
          names.each { |name| attrs[name] = [inflector.send(key_transformation, name).to_sym, block] }
        end
      end

      def _type
        self.class.type.nil? ? key_name : inflector.send(key_transformation, self.class.type).to_sym
      end

      def _key_name
        inflector.send(key_transformation, name).to_sym
      end

      def _relationships
        self.class.relationships.each_with_object({}) do |(name, opts), rels|
          rels[name] = opts.merge(
            key_name: inflector.send(key_transformation, name).to_sym,
            type: opts[:type] && inflector.send(key_transformation, opts[:type]).to_sym
          )
        end
      end

      def _key_transformation
        self.class.send(:key_transformation) || :underscore
      end
    end

    module ClassMethods
      include Helpers

      def resource(name = Undefined)
        _setting(:resource, name).tap do
          next if name == Undefined

          dsl_methods.each { |method_name| send(method_name) }
          yield if block_given?
          container.register("mappers.#{name}", memoize: true) { new } unless container.key?("mappers.#{name}")
        end
      end

      def links(*args, &block)
        type, name = args

        params = type ? {type => [name, block]} : {}

        if cumulative_setting?(:_links, params)
          _setting(:links, config.send(:_links).merge(params), {})
        else
          _setting(:links, params, {})
        end
      end

      def type(name = Undefined)
        _setting(:type, name)
      end

      def resource_identifier(id = :id)
        _setting(:resource_identifier, id, :id)
      end

      def key_transformation(name = Undefined)
        _setting(:key_transformation, name)
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

      def meta(**values, &block)
        _setting(:meta, [values, block], [{}, nil])
      end

      def one(name, **opts)
        key = opts.fetch(:as, name).to_sym
        relationships(**{key => opts.merge(method: name, cardinality: :one)})
      end

      def many(name, **opts)
        key = opts.fetch(:as, name).to_sym
        relationships(**{key => opts.merge(method: name, cardinality: :many)})
      end

      private

      def dsl_methods
        %i(links type resource_identifier attributes dynamic_attributes
           meta relationships key_transformation)
      end

      def container
        SaboTabby::Container
      end
    end
  end
end
