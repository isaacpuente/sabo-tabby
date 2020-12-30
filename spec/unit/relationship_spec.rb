# frozen_string_literal: true

RSpec.describe SaboTabby::Relationship do
  include_context "test_data"

  subject(:relationship) { described_class.new(parent) }

  let(:parent) { cat_mapper.resource }
  let(:options) { {include: [:hooman, :nap_spots]} }

  describe "#initialize" do
    it "sets readers" do
      expect(relationship.parent).to eq(parent)
      expect(relationship.parent_mapper).to eq(parent.mapper)
      expect(relationship.mappers).to eq(parent.mappers)
    end
  end
  describe "#call" do
    before do
      allow(cat_link).to receive(:for_relationship)
        .and_return(hooman_link.for_relationship(the_cat), {}, {}, {})
    end
    it "returns resource relationships for scope" do
      expect(relationship.(the_cat, **scope_settings))
        .to eq(relationship_result["relationships"])
    end
    context "no relationships" do
      let(:parent) { sand_box_mapper.resource }
      it "returns empty hash" do
        expect(relationship.(sand_box, **scope_settings)).to eq({})
      end
    end
  end
end
