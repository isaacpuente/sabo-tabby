# frozen_string_literal: true

require "sabo_tabby/mapper"
require "sabo_tabby/mapper/error"
require "sabo_tabby/mapper/pagination"

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
      one :hooman, type: :people
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
    link "nap-spot"
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
    end
    meta run_by: :cats
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

class Hooman
  attr_reader :id, :name, :babies, :nap_spots

  def initialize(id, name, babies = [], nap_spots = [])
    @id, @name, @babies, @nap_spots = id, name, babies, nap_spots
  end
end

class NapSpot
  attr_reader :spot_id, :name

  def initialize(id, name)
    @spot_id, @name = id, name
  end
end

class SandBox
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class Cat
  attr_reader :id, :name, :age, :family, :gender, :hooman, :nap_spots, :sand_box

  def initialize(id, name, age, family, gender, hooman, nap_spots, sand_box)
    @id, @name, @age, @family, @gender, @hooman, @nap_spots, @sand_box =
      id, name, age, family, gender, hooman, nap_spots, sand_box
  end
end

RSpec.shared_context "test_data" do
  let(:hooman) { Hooman.new(1, "Hooman name", [], [nap_spots[2]]) }
  let(:nap_spots) { [NapSpot.new(1, "Chair"), NapSpot.new(2, "Sofa"), NapSpot.new(3, "Bed")] }
  let(:sand_box) { SandBox.new(1) }
  let(:the_cat) {
    Cat
      .new(2, "Nibbler", 9, "Domestic", :f, hooman, [nap_spots[0], nap_spots[1]], sand_box)
      .tap { |cat| hooman.babies << cat }
  }
  let(:new_cat) {
    Cat
      .new(3, "Snuggles", 3, "Russian blue", :m, hooman, [], nil)
      .tap { |cat| hooman.babies << cat }
  }
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
      resource: instance_double("SaboTabby::Resource", document_id: "cat_1")
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
      resource: instance_double("SaboTabby::Resource", document_id: "people_1")
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
      resource: instance_double("SaboTabby::Resource", document_id: "nap_spot_1")
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
      resource: instance_double("SaboTabby::Resource", document_id: "sand_box_1"),
      compound_relationships: {},
      relationships: sand_box_mapper_relationships
    )
  }
  let(:cat_mapper_relationships) {
    {
      hooman: {method: :hooman, cardinality: :one},
      sand_box: {method: :sand_box, cardinality: :one},
      nap_spot: {method: :nap_spots, cardinality: :many}
    }
  }
  let(:hooman_mapper_relationships) {
    {baby: {as: :cats, method: :babies, cardinality: :one, type: :cat}}
  }
  let(:nap_spot_mapper_relationships) {
    {cat: {method: :cat, cardinality: :one}}
  }
  let(:sand_box_mapper_relationships) { {} }
  let(:relationship_result) {
    {
      relationships: {
        hooman: {data: {id: "1", type: "people"}},
        nap_spots: {data: [{id: "1", type: "nap_spot"}, {id: "2", type: "nap_spot"}]},
        sand_box: {data: {id: "1", type: "sand_box"}}
      }
    }
  }
  let(:relationship) { instance_double("SaboTabby::Relationships") }
  let(:dynamic_attributes) {
    [[:gender, proc { |value| value == :f ? "Ms. Le prr" : "Mr. Le prr" }]]
  }
  let(:options) { {} }
  let(:loaded_mappers) {
    {
      "cat" => cat_mapper,
      "hooman" => hooman_mapper,
      "nap_spot" => nap_spot_mapper,
      "sand_box" => sand_box_mapper
    }
  }
  let(:loaded_error_mappers) { {"validation_error" => validation_error_mapper} }
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
  let(:pager) {
    double(
      "Pager",
      total: 52,
      total_pages: 3,
      per_page: 20,
      current_page: 2,
      first_in_page: 21,
      last_in_page: 40,
      prev_page: 1,
      next_page: 3
    )
  }
  let(:custom_pager) {
    double(
      "CustomPager",
      total_records: 52,
      pages: 3,
      page_size: 20,
      this_page: 2,
      first: 21,
      last: 40,
      prev: 1,
      next: 3
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
