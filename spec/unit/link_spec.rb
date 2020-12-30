# frozen_string_literal: true

require "sabo_tabby/link"

RSpec.describe SaboTabby::Link do
  include_context "test_data"

  subject(:link) { described_class.new(mapper.resource) }

  let(:mapper) { hooman_mapper }
  let(:options) { {url: host} }

  describe "#initialize" do
    it "sets readers" do
      expect(link.resource).to eq(mapper.resource)
      expect(link.mapper).to eq(mapper)
      expect(link.options).to eq(mapper.resource.options)
      expect(link.url).to eq(link.options.fetch(:url, ""))
    end
  end

  describe "#for_resource" do
    it "returns resource link object" do
      expect(link.for_resource(hooman)).to eq("self" => "#{host}/hoomans/1")
    end
    context "no link mapper settings" do
      let(:mapper) { sand_box_mapper }
      it "returns empty hash" do
        expect(link.for_resource(sand_box)).to eq({})
      end

    end
    context "custom resource identifier" do
      let(:mapper) { nap_spot_mapper }
      it "returns empty hash" do
        expect(link.for_resource(nap_spots.first)).to eq("self" => "#{host}/nap-spots/1")
      end
    end
  end
  describe "#for_relationship" do
    context "placeholders" do
      context "resource_link" do
        it "replaces placeholder with resource_link" do
          expect(link.for_relationship(hooman, **scope_settings[:hooman][:cats])).to(
            eq(
              {"related" => "#{host}/hoomen/1/cats","self" => "#{host}/hoomen/1/relationships/cats"}
            )
          )
        end
      end
      context "resource_id" do
        let(:mapper) { cat_mapper }
        it "returns replaces placeholder with resopurce_id" do
          expect(link.for_relationship(hooman, **scope_settings[:hooman])).to(
            eq(
              {"related" => "#{host}/cats/1/mah-man","self" => "#{host}/cats/1/relationships/mah-man"}
            )
          )
        end

      end
      context "no link mapper settings" do
        let(:mapper) { nap_spot_mapper }
        it "returns empty hash" do
          expect(link.for_relationship(nap_spots.first, **scope_settings[:nap_spots])).to eq({})
        end
      end
    end
  end
end
