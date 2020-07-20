# frozen_string_literal: true

require "dry/system/container"

module SaboTabby
  class Container < Dry::System::Container
    configure do |config|
      config.root = Pathname(__FILE__).join("../..").realpath.dirname.freeze
      config.name = :sabo_tabby
      config.default_namespace = "sabo_tabby"
      config.auto_register = %w[system/sabo_tabby lib/sabo_tabby]
    end

    load_paths!("lib")
  end
end
