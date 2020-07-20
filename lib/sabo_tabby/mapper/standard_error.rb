# frozen_string_literal: true

require "sabo_tabby/mapper/error"

module SaboTabby
  module Mapper
    class StandardError
      include Mapper::Error

      resource :standard_error do
        detail(&:message)
      end
    end
  end
end
