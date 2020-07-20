# frozen_string_literal: true

require "dry-initializer"
require "dry-core"
require "sabo_tabby/mapper/settings"
require "sabo_tabby/resource"

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
      def initialize(**options)
        klass = self.class
        klass.settings.each do |key|
          param_name = key.to_s.split("_")[1..].join("_").to_sym
          name = param_name == :resource ? :name : param_name
          klass.param name, default: proc {
            case name
            when :type
              options.fetch(name, klass.send(key) || klass.send(:_resource))
            else
              options.fetch(name, klass.send(key))
            end
          }
        end
        klass.param :resource, default: proc { SaboTabby::Resource.new(self, options) }
        super()
      end

      def with(**options)
        tap { resource.with(**options) }
      end
    end

    module ClassMethods
      def resource(name = Undefined)
        _setting(:resource, name).tap do
          next if name == Undefined

          dsl_methods.each { |method_name| send(method_name) }
          yield if block_given?
          SaboTabby::Container.register("mappers.#{name}", new)
        end
      end

      def link(name = Undefined)
        _setting(:link, name)
      end

      def type(name = Undefined)
        _setting(:type, name)
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

      def relationships(one: {}, many: {}, &block)
        _nested_setting(:relationships, one: one, many: many, &block)
      end

      def meta(**values)
        _setting(:meta, values, {})
      end

      def one(name, **opts)
        key = inflector.singularize(opts.fetch(:as, name)).to_sym
        _relationships.one[key] = opts.merge(method: name)
      end

      def many(name, **opts)
        key = inflector.singularize(opts.fetch(:as, name)).to_sym
        _relationships.many[key] = opts.merge(method: name)
      end

      private

      def dsl_methods
        %i(link type resource_identifier attributes dynamic_attributes meta relationships)
      end

      def inflector
        @inflector ||= SaboTabby::Container[:inflector]
      end
    end
  end
end
