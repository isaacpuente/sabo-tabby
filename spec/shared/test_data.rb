# frozen_string_literal: true

class BaseTestClass
  def initialize(**args)
    args.each do |name, value|
      self.class.attr_accessor name
      instance_variable_set("@#{name}", value)
    end
  end
end

class Cat < BaseTestClass; end

class Hooman < BaseTestClass; end

class NapSpot < BaseTestClass; end

class SandBox < BaseTestClass; end

class Job < BaseTestClass; end

class Project < BaseTestClass; end

class ProjectType < BaseTestClass; end

class User < BaseTestClass; end

class Asset < BaseTestClass; end

class Tag < BaseTestClass; end

class Role < BaseTestClass; end

class Status < BaseTestClass; end

class ValidationError < StandardError; end

def new_asset(project, **data)
  Asset.new(
    id: data.fetch(:id, rand(1..100)),
    name: data.fetch(:name, "asset name #{rand(1.100)}"),
    cover_image: data.fetch(:cover_image, false),
    type: data.fetch(:type, 0),
    project: project,
    tags: data.fetch(:tags, [])
  )
end

def new_project(**data)
  Project.new(
    id: data.fetch(:id, rand(1..100)),
    name: data.fetch(:name, "project name #{rand(1..100)}"),
    description: data.fetch(:description, "description of a project #{rand(1..100)}"),
    created_at: Time.now,
    updated_at: Time.now,
    users: data.fetch(:users, []),
    assets: data.fetch(:assets, []),
    tags: data.fetch(:tags, []),
    type: data.fetch(:project_type, nil)
  )
end

def new_user(**data)
  User.new(
    id: data.fetch(:id, rand(1..100)),
    firstname: data.fetch(:firstname, "firstname #{rand(1..100)}"),
    lastname: data.fetch(:lastname, "lastname #{rand(1..100)}"),
    email: data.fetch(:email, "user_#{rand(1..100)}@domain.com"),
    status: data.fetch(:status, nil),
    projects: data.fetch(:projects, []),
    role: data.fetch(:role, nil)
  )
end

RSpec.shared_context "test_data" do

  let(:project_types) {
    [ProjectType.new(id: 1, name: "External"), ProjectType.new(id: 2, name: "Internal")]
  }
  let(:roles) { [Role.new(id: 1, name: "admin"), Role.new(id: 2, name: "designer")] }
  let(:statuses) { [Status.new(id: 1, name: "Unverified"), Status.new(id: 2, name: "Verified")] }
  let(:project) {
    new_project(
      id: 12,
      name: "EVVE",
      description: "Emptyness of Vanity, Vanity of Emptyness",
      project_type: project_types.last
    ).tap do |p|
      p.assets = Array.new(4) { |i| new_asset(p, id: i + 1, tags: tags.first(2)) }
      p.tags = tags.last(2)
      p.users = new_user(id: 1308, role: roles.first, projects: [p], status: statuses.last)
    end
  }
  let(:projects) {
    users = Array.new(3) { |i|
      new_user(id: i + 1, role: roles.sample, status: statuses.sample)
    }
    Array.new(5) { |i|
      new_project(id: i + 1, type: project_types.sample, tags: Array(tags.sample(1..2))).tap do |p|
        p.assets = Array.new(4) { new_asset(p, tags: Array(tags.sample(rand(1..4)))) }
        p.tags = Array(tags.sample(rand(1..4)))
        p.users = Array(users.sample(rand(1..3)))
        p.users.each { |u| u.projects = u.projects << p }
      end
    }
  }
  let(:tags) {
    [
      Tag.new(id: 1, name: "First tag"),
      Tag.new(id: 2, name: "Second tag"),
      Tag.new(id: 3, name: "Third tag"),
      Tag.new(id: 4, name: "Fourth tag")
    ]
  }
  let(:hooman) {
    Hooman.new(
      id: 1,
      name: "Hooman name",
      babies: [],
      nap_spots: [nap_spots[2]],
      jobs: jobs.first(2)
    )
  }
  let(:nap_spots) {
    [
      NapSpot.new(spot_id: 1, name: "Chair"),
      NapSpot.new(spot_id: 2, name: "Sofa"),
      NapSpot.new(spot_id: 3, name: "Bed")
    ]
  }
  let(:jobs) {
    [
      Job.new(id: 1, cat_id: 1, name: "Feed"),
      Job.new(id: 2, cat_id: 1, name: "Clean sandbox"),
      Job.new(id: 3, cat_id: 1, name: "Pet")
    ]
  }
  let(:sand_box) { SandBox.new(id: 1) }

  let(:the_cat) {
    Cat.new(
      id: 2,
      name: "Nibbler",
      age: 9,
      family: "Domestic",
      gender: :f,
      hooman: hooman,
      nap_spots: [nap_spots[0], nap_spots[1]],
      sand_box: sand_box
    ).tap { |cat| hooman.babies << cat }
  }

  let(:new_cat) {
    Cat.new(
      id: 3,
      name: "Snuggles",
      age: 3,
      family: "Russian blue",
      gender: :m,
      hooman: hooman,
      nap_spots: [],
      sand_box: nil
    ).tap { |cat| hooman.babies << cat }
  }
  let(:attribute_result) {
    {age: 9, family: "Domestic", gender: "Ms. Le prr", name: "Nibbler"}
  }
  let(:relationship_result) {
    {
      relationships: {
        hooman: {data: {id: "1", type: :people}, links: {related: "http://localhost/cats/2/mah-man", self:"http://localhost/cats/2/relationships/mah-man"}},
        nap_spots: {data: [
          {id: "1", type: :nap_spot}, {id: "2", type: :nap_spot}
        ]},
        sand_box: {data: {id: "1", type: :sand_box}}
      }
    }
  }
  let(:host) { "http://localhost" }
  let(:link_result) { {links: {}} }
  let(:dynamic_attributes) {
    {gender: ["gender", proc { |value| value == :f ? "Ms. Le prr" : "Mr. Le prr" }]}
  }
  let(:options) { {} }
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
  let(:scope_settings) {
    {
      hooman: scope_settings_hooman.merge(
        cats: scope_settings_cat,
        jobs: scope_settings_job,
        nap_spots: scope_settings_nap_spot
      ),
      sand_box: scope_settings_sandbox,
      nap_spots: scope_settings_nap_spot
    }
  }
  let(:custom_scope_settings) {
    {
      hooman: scope_settings_hooman.merge(
        cats: scope_settings_cat.merge(
          hooman: scope_settings_hooman.merge(
            cats: scope_settings_cat,
            jobs: scope_settings_job,
            nap_spots: scope_settings_nap_spot
          ),
          sand_box: scope_settings_sandbox,
          nap_spots: scope_settings_nap_spot
        ),
        jobs: scope_settings_job,
        nap_spots: scope_settings_nap_spot
      ),
      sand_box: scope_settings_sandbox,
      nap_spots: scope_settings_nap_spot
    }
  }
  let(:auto_compound_scope_settings) {
    {
      assets: {
        cardinality: :many,
        identifier: :id,
        include: true,
        mapper_name: :asset,
        method: :assets,
        project: {
          cardinality: :one,
          identifier: :id,
          mapper_name: :project,
          method: :project,
          scope: :project,
          type: :project,
          key_name: :project
        },
        scope: :assets,
        tags: {
          cardinality: :many,
          identifier: :id,
          include: true,
          mapper_name: :tag,
          method: :tags,
          scope: :tags,
          type: :tag,
          key_name: :tags
        },
        type: :asset,
        key_name: :assets
      },
      project_type: {
        as: :project_type,
        cardinality: :one,
        identifier: :id,
        include: true,
        mapper_name: :project_type,
        method: :type,
        scope: :type,
        type: :project_type,
        key_name: :project_type
      },
      tags: {
        cardinality: :many,
        identifier: :id,
        include: true,
        mapper_name: :tag,
        method: :tags,
        scope: :tags,
        type: :tag,
        key_name: :tags
      },
      users: {
        cardinality: :many,
        identifier: :id,
        include: true,
        links: {related: "%{resource_link}/users", self: "%{resource_link}/relationships/users"},
        mapper_name: :user,
        method: :users,
        projects: {
          cardinality: :many,
          identifier: :id,
          include: true,
          mapper_name: :project,
          method: :projects,
          scope: :projects,
          type: :project,
          key_name: :projects
        },
        role: {
          cardinality: :one,
          identifier: :id,
          include: true,
          mapper_name: :role,
          method: :role,
          scope: :role,
          type: :role,
          key_name: :role
        },
        scope: :users,
        type: :user,
        key_name: :users
      }
    }
  }
  let(:max_depth) { 4 }


  let(:scope_settings_cat) {
    {
      as: :cats,
      type: :cat,
      key_name: :cats,
      method: :babies,
      cardinality: :many,
      scope: :babies,
      identifier: :id,
      mapper_name: :cat,
      links: {related: "%{resource_link}/cats", self: "%{resource_link}/relationships/cats"},
    }
  }
  let(:scope_settings_hooman) {
    {
      type: :people,
      key_name: :hooman,
      method: :hooman,
      scope: :hooman,
      cardinality: :one,
      identifier: :id,
      links: {self: "cats/%{resource_id}/relationships/mah-man", related: "cats/%{resource_id}/mah-man"},
      mapper_name: :hooman
    }
  }
  let(:scope_settings_job) {
    {
      cardinality: :many,
      identifier: :id,
      method: :jobs,
      scope: :jobs,
      key_name: :jobs,
      type: :job,
      mapper_name: :job
    }
  }
  let(:scope_settings_nap_spot) {
    {
      scope: :nap_spots,
      key_name: :nap_spots,
      type: :nap_spot,
      identifier: :spot_id,
      cardinality: :many,
      method: :nap_spots,
      mapper_name: :nap_spot
    }
  }
  let(:scope_settings_sandbox) {
    {
      scope: :sand_box,
      key_name: :sand_box,
      type: :sand_box,
      identifier: :id,
      cardinality: :one,
      method: :sand_box,
      mapper_name: :sand_box
    }
  }

  include_context "mappers"
end
