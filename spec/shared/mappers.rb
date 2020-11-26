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
      many :users, include: true
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
      one :hooman, type: :people, links: {
        self: {},
        related: {}
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
      many :babies, as: :cats, type: :cat
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
  let(:cat_mapper) {
    instance_double(
      "CatMapper",
      name: :cat,
      resource_identifier: :id,
      type: :cat,
      attributes: %i(name age family),
      meta: {code_name: :feline},
      dynamic_attributes: dynamic_attributes,
      relationships: cat_mapper_relationships,
      compound_relationships: {},
      resource: instance_double(
        "SaboTabby::Resource",
        document_id: "cat_1",
        type: "cat"
      )
    )
  }
  let(:hooman_mapper) {
    instance_double(
      "HoomanMapper",
      name: :hooman,
      type: :people,
      attributes: %i(name),
      resource_identifier: :id,
      meta: {},
      relationships: hooman_mapper_relationships,
      compound_relationships: {},
      resource: instance_double(
        "SaboTabby::Resource",
        document_id: "people_1",
        type: "people"
      )
    )
  }
  let(:job_mapper) {
    instance_double(
      "JobMapper",
      name: :job,
      type: :job,
      attributes: %i(name),
      resource_identifier: :id,
      meta: {},
      relationships: job_mapper_relationships,
      compound_relationships: {},
      resource: instance_double(
        "SaboTabby::Resource",
        document_id: "job_1",
        type: "job"
      )
    )
  }
  let(:nap_spot_mapper) {
    instance_double(
      "NapSpotMapper",
      name: :nap_spots,
      type: :nap_spot,
      attributes: %i(name),
      meta: {if_i_fits: :i_sits},
      resource_identifier: :spot_id,
      relationships: nap_spot_mapper_relationships,
      compound_relationships: {},
      resource: instance_double(
        "SaboTabby::Resource",
        document_id: "nap_spot_1",
        type: "nap_spot"
      )
    )
  }
  let(:sand_box_mapper) {
    instance_double(
      "SandBoxMapper",
      name: :sand_box,
      type: :sand_box,
      attributes: [],
      meta: {},
      resource_identifier: :id,
      resource: instance_double(
        "SaboTabby::Resource",
        document_id: "sand_box_1",
        type: "sand_box"
      ),
      compound_relationships: {},
      relationships: sand_box_mapper_relationships
    )
  }
  let(:cat_mapper_relationships) {
    {
      hooman: {method: :hooman, cardinality: :one, links: {self: {}, related: {}}},
      sand_box: {method: :sand_box, cardinality: :one},
      nap_spots: {method: :nap_spots, cardinality: :many}
    }
  }
  let(:hooman_mapper_relationships) {
    {
      baby: {as: :cats, method: :babies, cardinality: :many, type: :cat},
      jobs: {method: :jobs, cardinality: :many},
      nap_spots: {method: :nap_spots, cardinality: :many}
    }
  }
  let(:job_mapper_relationships) {
    {cat: {method: :cat, cardinality: :one}}
  }
  let(:nap_spot_mapper_relationships) {
    {cat: {method: :cat, cardinality: :one}}
  }
  let(:sand_box_mapper_relationships) { {} }
  let(:loaded_mappers) {
    {
      "cat" => cat_mapper,
      "hooman" => hooman_mapper,
      "job" => job_mapper,
      "nap_spot" => nap_spot_mapper,
      "sand_box" => sand_box_mapper
    }
  }
  let(:loaded_error_mappers) { {"standard_error" => standard_error_mapper} }
  let(:validation_error_mapper) {
    instance_double(
      "ValidationErrorMapper",
      name: :validation_error,
      type: :validation_error,
      status: 422,
      title: "Validation error",
      detail: proc { |error| "#{error.message} Name must be filled" },
      code: "3",
      origin: proc { "/data/origin" },
      resource: instance_double("SaboTabby::Error")
    )
  }
  let(:standard_error_mapper) {
    instance_double(
      "SaboTabby::Mapper::StandardError",
      name: :standard_error,
      type: :standard_error,
      status: 400,
      title: "Error",
      detail: proc { |error| "#{error.message} User must exist." },
      code: "4",
      origin: proc { nil },
      resource: instance_double("SaboTabby::Error")
    )
  }
  let(:default_pagination_mapper) {
    instance_double(
      "SaboTabby::Mapper::DefaultPagination",
      name: :default_pagination,
      current: :current_page,
      first: :first_in_page,
      last: :last_in_page,
      next_page: :next_page,
      prev_page: :prev_page,
      page_size: :per_page,
      total_pages: :total_pages,
      total_records: :total,
      pager: pager
    )
  }
  let(:custom_pagination_mapper) {
    instance_double(
      "CustomPagination",
      name: :custom_pagination,
      current: :this_page,
      first: :first,
      last: :last,
      next_page: :next,
      prev_page: :prev,
      page_size: :page_size,
      total_pages: :pages,
      total_records: :total_records,
      pager: custom_pager
    )
  }
  before do
    %i(cat_mapper hooman_mapper nap_spot_mapper sand_box_mapper).each do |mapper|
      allow(send(mapper).resource).to receive(:options).and_return(options)
      allow(send(mapper).resource).to receive(:mapper).and_return(send(mapper))
      allow(send(mapper).resource).to receive(:mappers).and_return(loaded_mappers)
    end
  end
end
