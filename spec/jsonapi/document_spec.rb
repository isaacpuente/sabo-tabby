# frozen_string_literal: true

require "sabo_tabby/jsonapi/document"

RSpec.describe SaboTabby::JSONAPI::Document do
  include_context "test_data"

  subject(:document) { described_class.new(resource, options) }

  let(:resource) { the_cat }
  let(:options) { url_options }
  let(:url_options) { {url: host, skip_root_links: "true"} }

  describe "#call" do
    context "resource object" do
      let(:single_document_response) {
        {
          data: {
            id: String(Array(resource)[0].id),
            type: :cat,
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
              type: :cat,
              meta: {code_name: :feline},
              attributes: {
                age: Array(resource)[1].age,
                cat_years: 1,
                family: Array(resource)[1].family,
                gender: "Mr. Le prr",
                name: Array(resource)[1].name
              },
              relationships: {
                hooman: {
                  data: {id: "1", type: :people},
                  links: {related: "http://localhost/cats/3/mah-man", self: "http://localhost/cats/3/relationships/mah-man"}
                }
              }
            }
          ]
        }
      }
      let(:compound_response) {
        [
          {
            id: "1",
            type: :people,
            attributes: {name: hooman.name},
            relationships: {
              cats: {
                data: [{id: "2", type: :cat}],
                links: {
                  related: "#{options[:url]}/hoomen/1/cats",
                  self: "#{options[:url]}/hoomen/1/relationships/cats"
                }
              },
              jobs: {data: [{id: "1", type: :job}, {id: "2", type: :job}]},
              nap_spots: {data: [{id: "3", type: :nap_spot}]}
            },
            meta: {run_by: :cats},
            links: {self: "#{options[:url]}/hoomans/hooman-name-1"}
          },
          {
            id: "1",
            type: :nap_spot,
            attributes: {name: nap_spots[0].name},
            links: {self: "#{options[:url]}/nap-spots/1"},
            meta: {if_i_fits: :i_sits}
          },
          {
            id: "2",
            type: :nap_spot,
            attributes: {name: nap_spots[1].name},
            links: {self: "#{options[:url]}/nap-spots/2"},
            meta: {if_i_fits: :i_sits}
          },
          {id: "1", type: :sand_box}
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
              links: {self: "#{options[:url]}/nap-spots/1"},
              meta: {if_i_fits: :i_sits},
              type: :nap_spot
            }
          )
        end
        context "sparse fieldset" do
          let(:options) { {fields: {"cat" => %w(name age)}}.merge(url_options) }
          let(:resource) { the_cat }
          it "returns resource document with only requested fieldset" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: single_document_response[:data].merge(
                attributes: {age: Array(resource)[0].age, name: Array(resource)[0].name}
              )
            )
          end
        end
      end
      context "resource collection with relationships" do
        let(:resource) { [the_cat, new_cat] }
        it "returns resource document collection" do
          expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
          expect(document.call).to eq(document_collection_response)
        end
        context "sparse fieldset" do
          let(:options) { {fields: {"cat" => %w(name age)}}.merge(url_options) }
          it "returns resource document with only requested fieldset" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: document_collection_response[:data].map.with_index { |d, i|
                d.merge(attributes: {age: Array(resource)[i].age, name: Array(resource)[i].name})
              }
            )
          end
        end
      end
      context "compound document" do
        let(:options) { {include: %i(hooman nap_spots sand_box)}.merge(url_options) }
        context "single resource with relationships and included" do
          it "returns resource compound document" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: single_document_response[:data],
              included: compound_response
            )
          end
          context "sparse fieldset" do
            let(:options) {
              {include: %i(hooman nap_spots sand_box), fields: {"people" => %w(none)}}.merge(url_options)
            }
            it "returns resource compound document with filtered attributes" do
              expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
              expect(document.call).to eq(
                data: single_document_response[:data],
                included: [
                  compound_response[0].reject { |k, _| k == :attributes },
                  compound_response[1],
                  compound_response[2],
                  compound_response[3]
                ]
              )
            end
          end
        end
        context "single resource with relationships and nested included" do
          let(:options) { {include: %w(hooman.nap_spots nap_spots sand_box)}.merge(url_options) }
          let(:additional_nap_spot) {
            {
              id: "3",
              type: :nap_spot,
              attributes: {name: "Bed"},
              links: {self:"#{options[:url]}/nap-spots/3"},
              meta: {if_i_fits: :i_sits}
            }
          }
          it "returns resource compound document" do
            expect(JSON.generate(document.call)).to match_json_schema(:jsonapi)
            expect(document.call).to eq(
              data: single_document_response[:data],
              included: [
                compound_response[0],
                additional_nap_spot,
                compound_response[1],
                compound_response[2],
                compound_response[3]
              ]
            )
          end
        end
        xcontext "resource collection with relationships and included" do
          it "returns compound document"
        end
      end
      xcontext "meta" do
        it "returns document with meta object"
      end
      xcontext "pagination" do
        it "returns document with pagination objects"
      end
    end
    xcontext "error object" do
      it "returns error document"
    end
  end

  context "from unit" do
    let(:url_options) { {} }
    let(:mappers) { loader.mappers }
    let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }
    let(:pagination_meta) { {pages: 3, total: 52} }
    let(:pagination_links) {
      {
        first: "http://localhost?page[number]=1&page[size]=20",
        last: "http://localhost?page[number]=3&page[size]=20",
        next: "http://localhost?page[number]=3&page[size]=20",
        prev: "http://localhost?page[number]=1&page[size]=20",
        self: "http://localhost?page[number]=2&page[size]=20"
      }
    }
    let(:data) {
      {
        attributes: {age: 9, cat_years: 4, family: "Domestic", gender: "Ms. Le prr", name: "Nibbler"},
        id: "2",
        meta: {code_name: :feline},
        relationships: {
          hooman: {data: {id: "1", type: :people}, :links=>{:related=>"/cats/2/mah-man", :self=>"/cats/2/relationships/mah-man"}},
          nap_spots: {data: [{id: "1", type: :nap_spot}, {id: "2", type: :nap_spot}]},
          sand_box: {data: {id: "1", type: :sand_box}}
        },
        type: :cat
      }
    }
    let(:included) {
      [
        {
          type: :people,
          id: "1",
          attributes: {name: "Hooman name"},
          meta: {run_by: :cats},
          relationships: {
            cats: {
              data: [
                {type: :cat, id: "2"}
              ],
              links: {self: "/hoomen/1/relationships/cats", related: "/hoomen/1/cats"}
            },
            nap_spots: {
              data: [{type: :nap_spot, id: "3"}]
            },
            jobs: {
              data: [{type: :job, id: "1"}, {type: :job, id: "2"}]
            }
          },
          :links=>{:self=>"/hoomans/hooman-name-1"}}
      ]
    }

    describe "#initialize" do
      it "sets all readers" do
        expect(document.resource).to eq(resource)
        expect(document.options).to eq(options)
        expect(document.mappers).to eq(mappers)
      end
    end

    describe "#call" do
      let(:resource_document) { {data: data} }

      it "returns jsonapi resource document" do
        expect(document.call).to eq(resource_document)
      end
      context "collection" do
        let(:resource) { [the_cat] }
        let(:resource_document) { {data: [data]} }

        it "returns jsonapi resource document" do
          expect(document.call).to eq(resource_document)
        end
        context "paginated" do
          let(:options) { {pager: pager} }
          it "returns jsonapi resource document with links and meta" do
            expect(document.call)
              .to eq(resource_document.merge(meta: pagination_meta, links: pagination_links))
          end
        end
      end
      context "meta" do
        let(:options) { {meta: {run_by: :cats}} }

        it "returns jsonapi resource with meta object" do
          expect(document.call).to eq(resource_document.merge(meta: {run_by: :cats}))
        end
      end
      context "compound" do
        let(:options) { {include: %i(hooman nap_spot)} }
        let(:resource_document) { {data: data, included: included} }

        it "returns jsonapi resource with included object" do
          expect(document.call).to eq(resource_document)
        end
      end
      context "error" do
        let(:loader) { SaboTabby::Mapper::Loader.new(resource, **options) }
        let(:error_document) { {errors: [{status: "400", detail: "oops", title: "Error", code: ""}]} }
        let(:resource) { StandardError.new("oops") }

        context "through options" do
          let(:options) { {error: true} }
          it "returns jsonapi error document" do
            expect(document.call).to eq(error_document)
          end
        end
        context "resoure name" do
          let(:options) { {} }
          it "returns jsonapi error document" do
            expect(document.call).to eq(error_document)
          end
        end
      end
    end

    describe "#resource_name" do
      it "returns resource class name snake cased" do
        expect(document.resource_name(resource)).to eq(:cat)
      end
      context "collection" do
        let(:resource) { nap_spots }

        it "returns first element resource class name snake cased" do
          expect(document.resource_name(resource)).to eq(:nap_spot)
        end
      end
    end

    describe "#meta" do
      let(:options) { {meta: {everybody: :wants_to_be_a_cat}} }

      it "returns document's meta object" do
        expect(document.meta).to eq(meta: options[:meta])
      end
      context "no meta option" do
        let(:options) { {} }
        it "returns empty meta object" do
          expect(document.meta).to eq({})
        end
      end
    end

    describe "#compound_document" do
      let(:options) { {include: %i(hooman nap_spot)} }

      it "returns compound document" do
        expect(document.compound_document).to eq(included: included)
      end

      context "no include option" do
        let(:options) { {} }

        it "returns empty compound document" do
          expect(document.compound_document).to eq({})
        end
      end
    end

    describe "#collection?" do
      let(:resource) { [the_cat] }
      context "resource is array" do

        it "is true" do
          expect(document.collection?).to eq true
        end
      end
      context "resource is paginated" do
        let(:options) { {pager: pager} }

        it "is true" do
          expect(document.collection?).to eq true
        end
      end
    end

    describe "#paginated?" do
      let(:resource) { [the_cat] }
      context "without pager option" do
        it "is false" do
          expect(document.paginated?).to eq false
        end
      end
      context "with pager option" do
        let(:options) { {pager: pager} }

        it "is true" do
          expect(document.paginated?).to eq true
        end
      end
    end

    describe "#error?" do
      context "throug options" do
        let(:options) { {error: true} }

        it "is true if error option is pased" do
          expect(document.error?).to eq true
        end
      end
      context "resource name" do
        let(:options) { {} }
        let(:resource) { StandardError.new("oops") }

        it "is true if resource name contains error" do
          expect(document.error?).to eq true
        end
      end
    end
  end
end
