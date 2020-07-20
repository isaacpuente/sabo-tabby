# frozen_string_literal: true

require "dry-initializer"
require "sabo_tabby/mapper/settings"
require "sabo_tabby/error"

module SaboTabby
  module Mapper
    module Error
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
          klass.param :resource, default: proc { SaboTabby::Error.new(self, options) }
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
            SaboTabby::Container.register("mappers.errors.#{name}", new)
          end
        end

        def status(value = 400)
          _setting(:status, value, 400)
        end

        def type(value = Undefined)
          _setting(:type, value)
        end

        def code(value = "")
          _setting(:code, value, "")
        end

        def title(value = "Error")
          _setting(:title, value, "Error")
        end

        def detail(&block)
          blk = block_given? ? block : ->error { {message: error.message, origin: ""} }
          _setting(:detail, blk, nil)
        end

        private

        def dsl_methods
          %i(type status code title detail)
        end
      end
    end
  end
end
