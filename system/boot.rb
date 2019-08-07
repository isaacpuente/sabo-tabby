# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
  "pry-byebug load error"
end

require_relative "sabo_tabby/container"

SaboTabby::Container.booter.finalize!
SaboTabby::Container.importer.finalize!
SaboTabby::Container.auto_registrar.finalize!
