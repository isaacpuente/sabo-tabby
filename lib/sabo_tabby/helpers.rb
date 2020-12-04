# frozen_string_literal: true

module SaboTabby
  module Helpers
    def resource_name(scope)
      Array(scope).last
        .then { |scp| scp.instance_of?(Class) ? scp.name : scp.class.name }
        .then do |klass_name|
          inflector
            .demodulize(klass_name)
            .split(/(?=\p{upper}\p{lower}+)/)
            .map(&:downcase)
            .join("_")
        end
    end

    def container
      SaboTabby::Container
    end

    def inflector
      @inflector ||= container[:inflector]
    end
  end
end
