# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/document"

RSpec.describe SaboTabby::Document do
  include_context "test_data"

  subject(:document) { described_class.new(resource,options) }

  let(:resource) { the_cat }
  let(:options) { {} }

  describe "#call" do
    context "resource object" do
      let(:single_document_response) {
        {
          data: {
            id: String(Array(resource)[0].id),
            type: "cat",
            meta: {code_name: :feline},
            attributes: {
              age: Array(resource)[0].age,
              cat_years: 4,
              family: Array(resource)[0].family,
              gender: "Ms. Le prr",
              name: Array(resource)[0].name
            }
          }.merge(relationship_result)
        }
      }
      let(:document_collection_response) {
        {
          data: [
            single_document_response[:data],
            {
              id: String(Array(resource)[1].id),
              type: "cat",
              meta: {code_name: :feline},
              attributes: {
                age: Array(resource)[1].age,
                cat_years: 1,
                family: Array(resource)[1].family,
                gender: "Mr. Le prr",
                name: Array(resource)[1].name
              },
              relationships: {
                hooman: {data: {id: "1", type: "people"}}
              }
            }
          ]
        }
      }
      let(:compound_response) {
        [
          {
            id: "1",
            type: "people",
            attributes: {name: hooman.name},
            relationships: {
              cats: {data: [{id: "2", type: "cat"}]},
              nap_spots: {data: [{id: "3", type: "nap_spot"}]}
            },
            meta: {run_by: :cats}
          },
          {
            id: "1",
            type: "nap_spot",
            attributes: {name: nap_spots[0].name},
            meta: {if_i_fits: :i_sits}
          },
          {
            id: "2",
            type: "nap_spot",
            attributes: {name: nap_spots[1].name},
            meta: {if_i_fits: :i_sits}
          },
          {id: "1", type: "sand_box"}
        ]
      }
      context "single resource with relationships" do
        it "returns resource document" do
          expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
          expect(document.call).to eq(single_document_response)
        end
      end
      context "single resource without relationships" do
        let(:resource) { nap_spots[0] }
        it "returns resource document" do
          expect(document.call).to eq(
            data: {
              attributes: {name: "Chair"},
              id: "1",
              meta: {if_i_fits: :i_sits},
              type: "nap_spot"
            }
          )
        end
      end
      context "resource collection with relationships" do
        let(:resource) { [the_cat, new_cat] }
        it "returns resource document collection" do
          expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
          expect(document.call).to eq(document_collection_response)
        end
      end
      context "compound document" do
        let(:options) { {include: %i(hooman nap_spots sand_box)} }
        context "single resource with relationships and included" do
          it "returns resource compound document" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: single_document_response[:data],
              included: compound_response
            )
          end
        end
        context "single resource with relationships and nested included" do
          let(:options) { {include: %w(hooman.nap_spots nap_spots sand_box)} }
          it "returns resource compound document" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: single_document_response[:data],
              included: [
                compound_response[0],
                {id: "3", type: "nap_spot", attributes: {name: "Bed"}, meta: {if_i_fits: :i_sits}},
                compound_response[1],
                compound_response[2],
                compound_response[3]
              ]
            )
          end
        end
        context "resource collection with relationships and included"
      end
      context "meta"
      context "pagination"
    end
    context "error object"
  end
end
