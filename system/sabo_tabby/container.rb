# frozen_string_literal: true

require "dry/system/container"

module SaboTabby
  class Container < Dry::System::Container
    configure do |config|
      config.root = Pathname(__FILE__).join("../..").realpath.dirname.freeze
      config.name = :sabo_tabby
      config.component_dirs.add "lib"  do |dir|
        dir.default_namespace = "sabo_tabby"
      end
      config.component_dirs.add "system"
    end
  end
end
