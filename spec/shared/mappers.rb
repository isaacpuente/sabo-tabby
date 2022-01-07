# frozen_string_literal: true

require "sabo_tabby/mapper"
require "sabo_tabby/mapper/error"
require "sabo_tabby/mapper/pagination"

class ProjectMapper
  include SaboTabby::Mapper

  resource :project do
    attributes :name, :description
    attribute :created_at, :updated_at do |value, _resource, **_opts|
      value.iso8601(9)
    end
    links :self, :projects
    relationships do
      one :type, as: :project_type, include: true
      many :users, include: true, links: {
        self: "%{resource_link}/relationships/users",
        related: "%{resource_link}/users"
      }
      many :assets, include: true
      many :tags, include: true
    end
  end
end

class ProjectTypeMapper
  include SaboTabby::Mapper

  resource :project_type do
    attributes :name
    relationships do
      one :project
    end
  end
end

class UserMapper
  include SaboTabby::Mapper

  resource :user do
    attributes :firstname, :lastname, :email
    attribute :status do |value, _resource, **_opts|
      value.name
    end
    links :self, :users
    relationships do
      one :role, include: true
      many :projects, include: true
    end
  end
end

class RoleMapper
  include SaboTabby::Mapper

  resource :role do
    attributes :name
  end
end

class AssetMapper
  include SaboTabby::Mapper

  resource :asset do
    attributes :name, :cover_image, :type
    attribute :type do |value, _resource, **_opts|
      value.zero? ? "Image" : "Video"
    end
    relationships do
      one :project
      many :tags, include: true
    end
  end
end

class TagMapper
  include SaboTabby::Mapper

  resource :tag do
    attributes :name
  end
end

class CatMapper
  include SaboTabby::Mapper

  resource :cat do
    attributes :name, :age, :family
    attribute :gender do |value|
      value == :f ? "Ms. Le prr" : "Mr. Le prr"
    end
    attribute :cat_years do |_value, resource|
      resource.age / 2
    end
    relationships do
      one :hooman, links: {
        self: "cats/%{resource_id}/relationships/mah-man",
        related: "cats/%{resource_id}/mah-man"
      }
      one :sand_box
      many :nap_spots
    end
    meta code_name: :feline
  end
end

class NapSpotMapper
  include SaboTabby::Mapper

  resource :nap_spot do
    resource_identifier :spot_id
    attributes :name
    links :self, "nap-spots"
    relationships do
      one :cat
    end
    meta if_i_fits: :i_sits
  end
end

class SandBoxMapper
  include SaboTabby::Mapper
  resource :sand_box
end

class HoomanMapper
  include SaboTabby::Mapper

  resource :hooman do
    type :people
    attributes :name
    relationships do
      many :babies, as: :cats, type: :cat, links: {
        self: "%{resource_link}/relationships/cats",
        related: "%{resource_link}/cats"
      }
      many :nap_spots
      many :jobs
    end
    links :self, "hoomans" do |url, name, resource|
      "#{url}/#{name}/#{resource.name.downcase.split(" ").join("-")}-#{resource.id}"
    end
    meta run_by: :cats
  end
end

class JobMapper
  include SaboTabby::Mapper

  resource :job do
    attributes :name
    relationships do
      many :cats
    end
  end
end

class MapperWithKeyTransformation
  include SaboTabby::Mapper

  resource :sabo_tabby do
    attributes :name, :version
    key_transformation :camelize
  end
end

class EmptyMapper
  include SaboTabby::Mapper
end

class ValidationErrorMapper
  include SaboTabby::Mapper::Error

  resource :validation_error do
    status 422
    title "Validation error"
    code 3
    type :validation_error
    detail do |error|
      "Validation #{error.message}"
    end
    origin(&:origin)
  end
end

class WithoutArgErrorMapper
  include SaboTabby::Mapper::Error
  resource
end

class WithoutBlockErrorMapper
  include SaboTabby::Mapper::Error
  resource :error
end

class CustomPaginationMapper
  include SaboTabby::Mapper::Pagination

  resource :custom_pagination do
    current :this_page
    first :first
    last :last
    next_page :next
    prev_page :prev
    page_size :page_size
    total_pages :pages
    total_records :total_records
  end
end

class WithoutArgPaginationMapper
  include SaboTabby::Mapper::Pagination
  resource
end

RSpec.shared_context "mappers" do
  let(:key_transformation) { "underscore" }
  let(:cat_mapper_relationships) {
    {
      hooman: {
        method: :hooman,
        cardinality: :one,
        links: {related: "cats/%{resource_id}/mah-man", self: "cats/%{resource_id}/relationships/mah-man"},
        key_name: :hooman,
        type: nil
      },
      sand_box: {method: :sand_box, cardinality: :one, key_name: :sand_box, type: nil},
      nap_spots: {method: :nap_spots, cardinality: :many, key_name: :nap_spots, type: nil}
    }
  }
  let(:hooman_mapper_relationships) {
    {
      baby: {
        as: :cats,
        method: :babies,
        cardinality: :many,
        key_name: :cats,
        type: :cat,
        links: {related: "%{resource_link}/cats", self: "%{resource_link}/relationships/cats"}
      },
      jobs: {method: :jobs, cardinality: :many, key_name: :jobs, type: nil},
      nap_spots: {method: :nap_spots, cardinality: :many, key_name: :nap_spots, type: nil}
    }
  }
  let(:job_mapper_relationships) {
    {cat: {method: :cat, cardinality: :one, key_name: :cat, type: nil}}
  }
  let(:nap_spot_mapper_relationships) {
    {cat: {method: :cat, cardinality: :one, key_name: :cat, type: nil}}
  }
  let(:sand_box_mapper_relationships) { {} }
end
