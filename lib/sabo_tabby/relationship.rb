# frozen_string_literal: true

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Relationship
    extend Dry::Initializer
    extend Forwardable

    param :parent
    param :parent_mapper, default: proc { parent.mapper }
    param :options, default: proc { parent.options }

    def call(scope)
      build(parent_mapper.relationships.one, :one, scope)
        .then { |one| one.merge!(build(parent_mapper.relationships.many, :many, scope)) }
        .then { |r| r.empty? ? {} : {relationships: r} }
    end

    def with(parent)
      self.class.new(parent)
    end

    private

    def build(relationships, type, scope)
      relationships.each_with_object({}) do |(name, opts), result|
        rel_scope = relationship_scope(scope, opts[:method])
        next if skip?(rel_scope)

        result[opts.fetch(:as, opts[:method])] = send(type, opts.fetch(:as, name).to_s, rel_scope)
      end
    end

    def relationship_scope(scope, method)
      if scope.respond_to?(method)
        value = scope.send(method)
        return value unless value.nil? && scope.respond_to?("#{method}_id")

        id_object(scope, method).new
      elsif scope.respond_to?("#{method}_id")
        id_object(scope, method).new
      end
    end

    def skip?(scope)
      scope.nil? || (scope.is_a?(Array) && scope.empty?)
    end

    def one(name, scope)
      {
        data: {
          id: scope.send(parent.mappers[name].resource_identifier).to_s,
          type: parent.mappers[name].type.to_s
        }
      }
    rescue => e
      byebug
    end

    def many(name, scope)
      mapper_key = inflector.singularize(name)
      {
        data: scope.map { |s|
          {
            id: s.send(parent.mappers[mapper_key].resource_identifier).to_s,
            type: parent.mappers[mapper_key].type.to_s
          }
        }
      }
    rescue => e
      byebug
    end

    def inflector
      @inflector ||= SaboTabby::Container[:inflector]
    end

    def id_object(scope, method)
      Class.new do
        define_method :id do
          scope.send("#{method}_id")
        end
      end
    end
  end
end
