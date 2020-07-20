# frozen_string_literal: true

require "dry-configurable"
require "dry-core"

module SaboTabby
  module Settings
    include Dry::Core::Constants

    def self.extended(base)
      base.extend(Dry::Configurable)
    end

    def _setting(name, value, default = Undefined, &block)
      if respond_to?("_#{name}")
        return config.send("_#{name}") if setting_defined?(name, value, default)

        config["_#{name}"] = value
      else
        setting("_#{name}", value, reader: true, &block)
      end
    end

    def _nested_setting(name, **args, &block)
      if respond_to?("_#{name}")
        yield if block_given?
        send("_#{name}")
      else
        setting "_#{name}", reader: true do
          args.each do |k, v|
            setting(k, v, &block)
          end
        end
      end
    end

    def setting_defined?(name, value, default)
      [default, Undefined, config.send("_#{name}")].include?(value)
    end

    def setting?(name)
      respond_to?(name) &&
        !config.send(name).nil?
    end

    def cumulative_setting?(name, value)
      value.any? && setting?(name)
    end
  end
end
