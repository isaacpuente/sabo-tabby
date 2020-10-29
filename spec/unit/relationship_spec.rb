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
      expect(relationship.options).to eq(parent.options)
    end
  end

  describe "#call" do
    it "returns resource relationships for scope" do
      expect(relationship.(the_cat)).to eq(relationship_result[:relationships])
    end
    context "no relationships" do
      let(:parent) { sand_box_mapper.resource }
      it "returns empty hash" do
        expect(relationship.(sand_box)).to eq({})
      end
    end
  end
end
