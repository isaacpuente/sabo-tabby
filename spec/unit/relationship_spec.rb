# frozen_string_literal: true

RSpec.describe SaboTabby::Relationship do
  include_context "test_data"

  subject(:relationship) { described_class.new }

  let(:parent) { cat_mapper.resource }
  let(:options) { {include: [:hooman, :nap_spots]} }

  describe "#call" do
    it "returns resource relationships for scope" do
      expect(relationship.(cat_mapper, the_cat, **scope_settings))
        .to eq(relationship_result[:relationships])
    end
    context "no relationships" do
      let(:parent) { sand_box_mapper.resource }
      it "returns empty hash" do
        expect(relationship.(sand_box_mapper, sand_box, **scope_settings)).to eq({})
      end
    end
  end
end
