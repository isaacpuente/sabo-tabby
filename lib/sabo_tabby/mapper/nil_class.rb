# frozen_string_literal: true

require "sabo_tabby/mapper"

module SaboTabby
  module Mapper
    class NilClass
      include SaboTabby::Mapper

      resource :nil_class
    end
  end
end
