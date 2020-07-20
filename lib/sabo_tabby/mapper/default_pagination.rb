# frozen_string_literal: true

require "sabo_tabby/mapper/pagination"

module SaboTabby
  module Mapper
    class DefaultPagination
      include SaboTabby::Mapper::Pagination

      resource :default_pagination
    end
  end
end
