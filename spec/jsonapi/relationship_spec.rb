# frozen_string_literal: true

require "sabo_tabby/mapper/loader"
require "sabo_tabby/jsonapi/relationship"

RSpec.describe SaboTabby::JSONAPI::Relationship do
  include_context "test_data"

  subject(:relationship) { described_class.new(parent) }

  let(:parent) { CatMapper.new.resource(**options) }
  let(:options) { {include: [:hooman, :nap_spots], url: "http://localhost"} }
  let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }

  describe "#initialize" do
    it "sets readers" do
      expect(relationship.parent).to eq(parent)
      expect(relationship.parent_mapper).to eq(parent.mapper)
      expect(relationship.mappers).to eq(parent.mappers)
    end
  end
  describe "#call" do
    it "returns resource relationships for scope" do
      expect(relationship.(the_cat, **loader.scope_settings))
        .to eq(relationship_result[:relationships])
    end
    context "no relationships" do
      let(:parent) { SandBoxMapper.new.resource }
      it "returns empty hash" do
        expect(relationship.(sand_box, **loader.scope_settings)).to eq({})
      end
    end
  end
end
