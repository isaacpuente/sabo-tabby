# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "sabo_tabby/mapper/settings"

module SaboTabby
  module Mapper
    module Pagination
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
              when :first, :last, :current, :total_pages, :next_page,
                :prev_page, :page_size, :total_records
                options.fetch(name, pager.nil? ? klass.send(key) : pager.send(klass.send(key)))
              else
                options.fetch(param_name, klass.send(key))
              end
            }
          end
          klass.param :pager, default: proc { options[:pager] }

          super()
        end

        def with(**options)
          self.class.new(**options)
        end
      end

      module ClassMethods
        def resource(name = Undefined)
          _setting(:resource, name).tap do
            next if name == Undefined

            dsl_methods.each { |method_name| send(method_name) }
            yield if block_given?
            SaboTabby::Container.register("mappers.pagers.#{name}", memoize: true) { new }
          end
        end

        def current(value = :current_page)
          _setting(:current, value, :current_page)
        end

        def total_pages(value = :total_pages)
          _setting(:total_pages, value, :total_pages)
        end

        def first(value = :first_in_page)
          _setting(:first, value, :first_in_page)
        end

        def last(value = :last_in_page)
          _setting(:last, value, :last_in_page)
        end

        def next_page(value = :next_page)
          _setting(:next_page, value, :next_page)
        end

        def prev_page(value = :prev_page)
          _setting(:prev_page, value, :prev_page)
        end

        def total_records(value = :total)
          _setting(:total_records, value, :total)
        end

        def page_size(value = :per_page)
          _setting(:page_size, value, :per_page)
        end

        private

        def dsl_methods
          %i(current first last next_page prev_page
             page_size total_pages total_records)
        end
      end
    end
  end
end
