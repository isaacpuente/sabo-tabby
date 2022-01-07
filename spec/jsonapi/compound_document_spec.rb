# frozen_string_literal: true

require "sabo_tabby/jsonapi/compound_document"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::JSONAPI::CompoundDocument do
  include_context "test_data"

  subject(:compound) { described_class.new(loader, options) }

  let(:mappers) { loader.mappers }
  let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }
  let(:options) { {include: [:hooman, :nap_spots]} }
  let(:scope) { the_cat }
  describe "#call" do
    let(:compound_document) {
      {
        hooman: {
          id: "1",
          type: :people,
          attributes: {name: hooman.name},
          links: {self: "/hoomans/hooman-name-1"},
          meta: {run_by: :cats},
          relationships: {
            cats: {data: [{id: "2", type: :cat}], links: {related: "/hoomen/1/cats", self: "/hoomen/1/relationships/cats"}},
            nap_spots: {data: [{type: :nap_spot, id: "3"}]},
            jobs: {data: [{type: :job, id: "1"}, {type: :job, id: "2"}]}
          }
        },
        nap_spot: [
          {
            id: "1",
            type: :nap_spot,
            attributes: { name: nap_spots[0].name },
            meta: {if_i_fits: :i_sits},
            links: {self: "/nap-spots/1"}
          },
          {
            id: "2",
            type: :nap_spot,
            attributes: {name: nap_spots[1].name},
            meta: {if_i_fits: :i_sits},
            links: {self: "/nap-spots/2"}
          },
          {
            id: "3",
            type: :nap_spot,
            attributes: {name: nap_spots[2].name},
            meta: {if_i_fits: :i_sits},
            links: {self: "/nap-spots/3"}
          }
        ]
      }
    }
    context "no includes" do
      let(:loader) {
        instance_double(
          "SaboTabby::Loader",
          mappers: {},
          compound_paths: [],
          scope_settings: {},
          compound_mappers: {}
        )
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
    end
    context "nested includes" do
      let(:options) { {include: %w(hooman.nap_spots nap_spots)} }
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
    end
    xcontext "auto compound option" do
      it "returns compound document"
    end
  end
end
