# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/document/compound"

RSpec.describe SaboTabby::Document::Compound do
  include_context "test_data"

  subject(:compound) { described_class.new(loader, options) }

  let(:loader) {
    instance_double(
      "SaboTabby::Loader",
      mappers: mappers,
      compound_paths: [:hooman, :nap_spot]
    )
  }
  let(:mappers) { loaded_mappers }
  let(:options) { {include: [:hooman, :nap_spots]} }
  let(:scope) { the_cat }
  let(:hooman_mapper_resource) {
    instance_double("SaboTabby::Resource", id: 1, type: :people, name: :hooman, document_id: "people_1")
  }
  let(:nap_spot_mapper_resource) {
    instance_double("SaboTabby::Resource", id: 1, type: :nap_spot,  name: :nap_spot)
  }
  describe "#call" do
    before do
      allow(hooman_mapper).to(
        receive(:resource).with(mappers: mappers, **options).and_return(hooman_mapper_resource)
      )
      allow(hooman_mapper_resource).to(
        receive(:document).with(hooman).and_return(compound_document[:hooman])
      )
      allow(nap_spot_mapper).to(
        receive(:resource).with(mappers: mappers, **options).and_return(nap_spot_mapper_resource)
      )
      allow(nap_spot_mapper_resource).to(
        receive(:document).with(nap_spots[0]).and_return(compound_document[:nap_spot][0])
      )
      allow(nap_spot_mapper_resource).to(
        receive(:document_id).with(nap_spots[0]).and_return("nap_spot_1")
      )
      allow(nap_spot_mapper_resource).to(
        receive(:document).with(nap_spots[1]).and_return(compound_document[:nap_spot][1])
      )
      allow(nap_spot_mapper_resource).to(
        receive(:document_id).with(nap_spots[1]).and_return("nap_spot_2")
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
      let(:loader) {
        instance_double("SaboTabby::Loader", mappers: {}, compound_paths: [])
      }
      let(:options) { {} }
      it "returns empty compound document" do
        expect(compound.(scope)).to eq({})
      end
    end
    context "flat include" do
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
        expect(nap_spot_mapper).to receive(:resource).exactly(2).times

        compound.(scope)
      end
      it "sends document message to each mappers resource" do
        expect(hooman_mapper_resource)
          .to receive(:document).with(hooman).exactly(1).times
        expect(nap_spot_mapper_resource)
          .to receive(:document).with(nap_spots[0]).exactly(1).times
        expect(nap_spot_mapper_resource)
          .to receive(:document).with(nap_spots[1]).exactly(1).times

        compound.(scope)
      end
    end
    context "nested includes" do
      let(:loader) {
        instance_double(
          "SaboTabby::Loader",
          mappers: mappers,
          compound_paths: %w(hooman.nap_spots nap_spot)
        )
      }
      let(:options) { {include: %w(hooman.nap_spots nap_spots)} }
      before do
        allow(nap_spot_mapper_resource).to(
          receive(:document).with(nap_spots[2]).and_return(compound_document[:nap_spot][2])
        )
        allow(nap_spot_mapper_resource).to(
          receive(:document_id).with(nap_spots[2]).and_return("nap_spot_3")
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
        expect(nap_spot_mapper).to receive(:resource).exactly(3).times

        compound.(scope)
      end
      it "sends document message to each mappers resource" do
        expect(hooman_mapper_resource)
          .to receive(:document).with(hooman).exactly(1).times
        expect(nap_spot_mapper_resource)
          .to receive(:document).with(nap_spots[0]).exactly(1).times
        expect(nap_spot_mapper_resource)
          .to receive(:document).with(nap_spots[1]).exactly(1).times
        expect(nap_spot_mapper_resource)
          .to receive(:document).with(nap_spots[2]).exactly(1).times

        compound.(scope)
      end
    end
    xcontext "auto compound option" do
      it "returns compound document"
    end
  end
end
