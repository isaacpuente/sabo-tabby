# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/document/compound"

RSpec.describe SaboTabby::Document::Compound do
  include_context "test_data"

  subject(:compound) { described_class.new(mappers, options) }

  let(:mappers) { loaded_mappers }
  let(:options) { {include: [:hooman, :nap_spots]} }
  let(:scope) { the_cat }

  describe "#call" do
    before do
      allow(hooman_mapper.resource).to(
        receive(:with).with(mappers: mappers, **options).and_return(hooman_mapper.resource)
      )
      allow(hooman_mapper.resource).to(
        receive(:document).with(hooman).and_return(compound_document[:hooman])
      )
      allow(nap_spot_mapper.resource).to(
        receive(:with).with(mappers: mappers, **options).and_return(nap_spot_mapper.resource)
      )
      allow(nap_spot_mapper.resource).to(
        receive(:document).with(nap_spots[0]).and_return(compound_document[:nap_spot][0])
      )
      allow(nap_spot_mapper.resource).to(
        receive(:document).with(nap_spots[1]).and_return(compound_document[:nap_spot][1])
      )
    end
    let(:compound_document) {
      {
        hooman: {
          id: "1",
          type: "people",
          attributes: {
            name: hooman.name
          }
        },
        nap_spot: [
          {
            id: "1",
            type: "nap_spot",
            attributes: {
              name: nap_spots[0].name
            }
          },
          {
            id: "2",
            type: "nap_spot",
            attributes: {
              name: nap_spots[1].name
            }
          },
          {
            id: "3",
            type: "nap_spot",
            attributes: {
              name: nap_spots[2].name
            }
          }
        ]
      }
    }
    context "no includes" do
      let(:options) { {} }
      it "returns empty compound document" do
        expect(compound.(scope)).to eq({})
      end
    end
    context "unnested include" do
      it "returns compound document" do
        expect(compound.(scope))
          .to eq(
            included: [
              compound_document[:hooman],
              compound_document[:nap_spot][0],
              compound_document[:nap_spot][1]
            ]
          )
      end
      it "sends message to resource mapper for each include" do
        expect(hooman_mapper).to receive(:resource).exactly(1).times
        expect(nap_spot_mapper).to receive(:resource).exactly(1).times

        compound.(scope)
      end
      it "sends options and loaded mappers to each mappers resource" do
        expect(hooman_mapper.resource)
          .to receive(:with).with(mappers: mappers, **options).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:with).with(mappers: mappers, **options).exactly(1).times

        compound.(scope)
      end
      it "sends document message to each mappers resource" do
        expect(hooman_mapper.resource)
          .to receive(:document).with(hooman).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:document).with(nap_spots[0]).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:document).with(nap_spots[1]).exactly(1).times

        compound.(scope)
      end
    end
    context "nested includes" do
      let(:options) { {include: %w(hooman.nap_spots nap_spots)} }
      before do
        allow(nap_spot_mapper.resource).to(
          receive(:document).with(nap_spots[2]).and_return(compound_document[:nap_spot][2])
        )
      end
      it "returns compound document" do
        expect(compound.(scope))
          .to eq(
            included: [
              compound_document[:hooman],
              compound_document[:nap_spot][2],
              compound_document[:nap_spot][0],
              compound_document[:nap_spot][1]
            ]
          )
      end
      it "sends message to resource mapper for each include" do
        expect(hooman_mapper).to receive(:resource).exactly(1).times
        expect(nap_spot_mapper).to receive(:resource).exactly(1).times

        compound.(scope)
      end
      it "sends options and loaded mappers to each mappers resource" do
        expect(hooman_mapper.resource)
          .to receive(:with).with(mappers: mappers, **options).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:with).with(mappers: mappers, **options).exactly(1).times

        compound.(scope)
      end
      it "sends document message to each mappers resource" do
        expect(hooman_mapper.resource)
          .to receive(:document).with(hooman).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:document).with(nap_spots[0]).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:document).with(nap_spots[1]).exactly(1).times
        expect(nap_spot_mapper.resource)
          .to receive(:document).with(nap_spots[2]).exactly(1).times

        compound.(scope)
      end
    end
  end

  describe "#with" do
    it "sets mappers and options ivars" do
      cd = compound.with({}, {})
      expect(cd.mappers).to eq({})
      expect(cd.options).to eq({})
    end
    it "returns new instance" do
      cd = compound.with({}, {})
      expect(cd).not_to eq(compound)
    end
  end
end
