# frozen_string_literal: true

module SaboTabby
  module Helpers
    def resource_name(scope, exclude_word = "Mapper")
      Array(scope).last
        .then { |scp| scp.class == Class ? scp.name : scp.class.name }
        .then do |klass_name|
          klass_name
            .split("::")
            .last
            .split(/(?=\p{upper}\p{lower}+)/)
            .reject { |n| n == exclude_word }
            .map(&:downcase).join("_")
        end
    end
  end
end
