# frozen_string_literal: true

require "sabo_tabby/jsonapi/attribute"

RSpec.describe SaboTabby::JSONAPI::Attribute do
  include_context "test_data"

  subject(:resource) { described_class.new(mapper.resource(**options)) }

  let(:mapper) { CatMapper.new }

  describe "#initialize" do
    it "sets readers" do
      expect(resource.resource).to eq(mapper.resource)
      expect(resource.mapper).to eq(mapper)
      expect(resource.options).to eq(mapper.resource.options)
    end
  end

  describe "#call" do
    context "attributes" do
      let(:mapper) { NapSpotMapper.new }
      it "returns attributes" do
        expect(resource.call(nap_spots[1]))
          .to eq(name: nap_spots[1].name)
      end
    end
    context "attributes and dynamic attributes" do
      it "returns both" do
        expect(resource.call(the_cat)).to eq(
          age: the_cat.age,
          family: the_cat.family,
          name: the_cat.name,
          gender: "Ms. Le prr",
          cat_years: 4
        )
      end
    end
  end

  describe "#attributes" do
    it "returns defined resource attributes hash" do
      expect(resource.attributes(the_cat))
        .to eq(
          age: the_cat.age,
          family: the_cat.family,
          name: the_cat.name
        )
    end
    context "sparse fieldset" do
      let(:options) { {fields: {"cat" => %w(name age)}} }
      it "returns filtered attributes hash" do
        expect(resource.attributes(the_cat))
          .to eq(name: the_cat.name, age: the_cat.age)
      end
      context "no attributes" do
        let(:options) { {fields: {"cat" => []}} }
        it "returns empty attributes hash" do
          expect(resource.attributes(the_cat)).to eq({})
        end
      end
    end
  end

  describe "#dynamic_attributes" do
    it "returns defined resource dynamic attributes hash" do
      expect(resource.dynamic_attributes(the_cat))
        .to eq(gender: "Ms. Le prr", cat_years: 4)
    end
    context "sparse fieldset" do
      let(:options) { {fields: {"cat" => %w(gender)}} }
      it "returns filtered attributes hash" do
        expect(resource.dynamic_attributes(the_cat))
          .to eq(gender: "Ms. Le prr")
      end
      context "no attributes" do
        let(:options) { {fields: {"cat" => []}} }
        it "returns empty attributes hash" do
          expect(resource.dynamic_attributes(the_cat)).to eq({})
        end
      end
    end
  end
end
