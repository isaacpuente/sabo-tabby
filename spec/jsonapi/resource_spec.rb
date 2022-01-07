# frozen_string_literal: true

require "sabo_tabby/jsonapi/resource"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::JSONAPI::Resource do
  include_context "test_data"

  subject(:resource) { described_class.new(mapper, options) }

  let(:cat_mapper) { CatMapper.new }
  let(:mapper) { cat_mapper }
  let(:mappers) { {cat_mapper.name.to_s => cat_mapper} }

  describe "#initialize" do
    it "sets readers" do
      expect(resource.mapper).to eq(cat_mapper)
      expect(resource.options).to eq(options)
      expect(resource.mappers).to eq(mappers)
    end
  end

  describe "#id" do
    context "default resource_identifier" do
      it "returns scope's identifier value" do
        expect(resource.id(the_cat)).to eq(the_cat.id)
      end
    end
    context "custom resource_identifier" do
      subject(:resource) { described_class.new(NapSpotMapper.new, options) }
      it "returns scope's identifier value" do
        expect(resource.id(nap_spots[0])).to eq(nap_spots[0].spot_id)
      end
    end
    context "scope is an integer" do
      it "returns scope" do
        expect(resource.id(1)).to eq(1)
      end
    end
  end

  describe "#identifier" do
    it "returns idetnifier hash" do
      expect(resource.identifier(the_cat))
        .to eq(id: the_cat.id.to_s, type: cat_mapper.type)
    end
  end

  describe "#attributes" do
    it "returns defined resource attributes hash" do
      expect(resource.attributes(the_cat))
        .to eq(
          attributes: {
            age: the_cat.age,
            family: the_cat.family,
            name: the_cat.name,
            gender: "Ms. Le prr",
            cat_years: 4
          }
        )
    end
  end

  describe "#document" do
    context "with scope settings" do
      let(:options) { {url: "http://localhost"} }
      let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }
      it "returns resource document" do
        expect(resource.document(the_cat, loader.scope_settings)).to eq(
          {
            id: "2",
            type:  :cat,
            meta: {code_name: :feline},
            attributes: {
              age:9,
              family: "Domestic",
              gender: "Ms. Le prr",
              name: "Nibbler",
              cat_years: 4
            }
          }.merge(relationship_result)
        )
      end
    end
    it "returns resource document" do
      expect(resource.document(the_cat)).to eq(
        {
          id: "2",
          type:  :cat,
          meta: {code_name: :feline},
          attributes: {
            age:9,
            family: "Domestic",
            gender: "Ms. Le prr",
            name: "Nibbler",
            cat_years: 4
          }
        }
      )
    end
  end

  describe "#meta" do
    context "no meta mapper setting" do
      let(:mapper) { HoomanMapper.new }
      it "returns empty object" do
        expect(resource.meta(hooman)).to eq({meta: {run_by: :cats}})
      end
    end
    it "returns resource meta object" do
      expect(resource.meta(the_cat)).to eq(meta: {code_name: :feline})
    end
  end
end
