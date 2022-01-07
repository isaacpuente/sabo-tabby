# frozen_string_literal: true

require "sabo_tabby/jsonapi/link"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::JSONAPI::Link do
  include_context "test_data"

  subject(:link) { described_class.new(mapper.resource) }

  let(:mapper) { HoomanMapper.new }


  describe "#initialize" do
    it "sets readers" do
      expect(link.resource).to eq(mapper.resource)
      expect(link.mapper).to eq(mapper)
      expect(link.options).to eq(options)
      expect(link.url).to eq("")
    end
  end

  describe "#for_resource" do
    it "returns resource link object" do
      expect(link.for_resource(hooman)).to eq(self: "/hoomans/hooman-name-1")
    end
    context "no link mapper settings" do
      let(:mapper) { SandBoxMapper.new }
      it "returns empty hash" do
        expect(link.for_resource(sand_box)).to eq({})
      end

    end
    context "custom resource identifier" do
      let(:mapper) { NapSpotMapper.new }
      it "returns empty hash" do
        expect(link.for_resource(nap_spots.first)).to eq(self: "/nap-spots/1")
      end
    end
  end
  describe "#for_relationship" do
    let(:loader) { SaboTabby::Mapper::Loader.new(hooman, **options) }
    context "placeholders" do
      context "resource_link" do
        before { the_cat }

        it "replaces placeholder with resource_link" do
          expect(link.for_relationship(hooman, **loader.scope_settings[:cats])).to(
            eq(
              {related: "/hoomen/1/cats", self: "/hoomen/1/relationships/cats"}
            )
          )
        end
      end
      context "resource_id" do
        let(:mapper) { CatMapper.new }
        let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }
        before { hooman }

        it "returns replaces placeholder with resopurce_id" do
          expect(link.for_relationship(hooman, **loader.scope_settings[:hooman])).to(
            eq(
              {related: "/cats/1/mah-man", self: "/cats/1/relationships/mah-man"}
            )
          )
        end

      end
      context "no link mapper settings" do
        let(:mapper) { NapSpotMapper.new }
        it "returns empty hash" do
          expect(link.for_relationship(nap_spots.first, **loader.scope_settings[:nap_spots])).to eq({})
        end
      end
    end
  end
end
