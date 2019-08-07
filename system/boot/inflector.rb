# frozen_string_literal: true

SaboTabby::Container.boot :inflector do |system|
  init do
    require "dry/inflector"
  end

  start do
    inflector = Dry::Inflector.new do |inflections|
      inflections.singular "status", "status"
      inflections.singular "statuses", "status"
    end

    system.register :inflector, inflector
  end
end
