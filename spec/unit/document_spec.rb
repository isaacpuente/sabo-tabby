# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/document"
require "sabo_tabby/mapper/default_pagination"

RSpec.describe SaboTabby::Document do
  include_context "test_data"

  subject(:document) { described_class.new(resource, options) }

  let(:resource) { the_cat }
  let(:options) { {} }
  let(:mappers) { loaded_mappers }
  let(:pagination) { instance_double("SaboTabby::Pagination", with: with_pagination) }
  let(:with_pagination) {
    instance_double("SaboTabby::Pagination", meta: pagination_meta, links: pagination_links)
  }
  let(:pagination_meta) { {total: 32, pages: 2} }
  let(:pagination_links) { {self: "", last: "", prev: "", next: ""} }
  let(:default_pagination) { instance_double("SaboTabby::Mapper::DefaultPagination") }
  let(:compound_document) {
    instance_double(
      "SaboTabby::Document::Compound",
      with: with_compound_document
    )
  }
  let(:with_compound_document) {
    instance_double(
      "SaboTabby::Document::Compound",
      mappers: mappers,
      options: options,
      call: {included: included}
    )
  }
  let(:data) {
    {
      id: "1",
      type: "cat",
      attributes: {
        name: "Nibbler"
      }
    }
  }
  let(:included) { [{id: "3", type: "people"}, {id: "1", type: "nap_spot"}] }

  before do
    SaboTabby::Container.stub("document.compound", compound_document) if options[:include]
    SaboTabby::Container.stub("pagination", pagination) if options[:pager]

    stub_const(
      "SaboTabby::Mapper::Loader",
      class_double("SaboTabby::Mapper::Loader", for: mappers)
    )
  end

  after do
    SaboTabby::Container.unstub("document.compound")
    SaboTabby::Container.unstub("pagination") if options[:pager]
  end

  describe "#initialize" do
    it "sets all readers" do
      expect(document.resource).to eq(resource)
      expect(document.options).to eq(options)
      expect(document.mappers).to eq(mappers)
    end
  end

  describe "#call" do
    before do
      allow(cat_mapper.resource).to receive(:with)
        .with(mappers: mappers)
        .and_return(cat_mapper.resource)
      allow(cat_mapper.resource)
        .to receive(:document).with(resource).and_return(resource_document[:data])
    end
    let(:resource_document) { {data: data} }

    it "returns jsonapi resource document" do
      expect(document.call).to eq(resource_document)
    end
    context "collection" do
      before do
        allow(cat_mapper.resource)
          .to receive(:document).with(resource.first).and_return(resource_document[:data].first)
      end
      let(:resource) { [the_cat] }
      let(:resource_document) { {data: [data]} }

      it "returns jsonapi resource document" do
        expect(document.call).to eq(resource_document)
      end
      context "paginated" do
        before do
          allow(pagination).to receive(:with).with(mappers, {pager: pager}).and_return(pagination)
        end
        let(:options) { {pager: double("Pager")} }
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
      let(:resource_document) { {data: [data], included: included} }

      it "returns jsonapi resource with included object" do
        expect(document.call).to eq(resource_document)
      end
    end
    context "error" do
      before do
        allow(standard_error_mapper.resource).to receive(:with)
          .with(mappers: mappers)
          .and_return(standard_error_mapper.resource)
        allow(standard_error_mapper.resource)
          .to receive(:document).with(resource).and_return(error_document[:errors].first)
      end

      let(:mappers) { {standard_error_mapper.name.to_s => standard_error_mapper} }
      let(:error_document) { {errors: [{status: "400", message: "oops", title: "Error"}]} }
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
      expect(document.resource_name).to eq("cat")
    end
    context "collection" do
      let(:resource) { nap_spots }

      it "returns first element resource class name snake cased" do
        expect(document.resource_name).to eq("nap_spot")
      end
    end
  end

  describe "#mapper_resource" do
    before do
      allow(cat_mapper.resource).to receive(:with)
        .with(mappers: mappers)
        .and_return(cat_mapper.resource)
    end

    it "returns mapper_resource with mappers passed" do
      expect(cat_mapper).to receive(:resource).exactly(2).times
      expect(cat_mapper.resource).to receive(:with).with(mappers: mappers).exactly(1).times

      document.mapper_resource
    end
    it "passess loaded mappers" do
      expect(document.mapper_resource).to eq(cat_mapper.resource)
    end
  end

  describe "#meta" do
    let(:options) { {meta: {everybody: :wants_to_be_a_cat}} }

    it "returns document's meta object" do
      expect(document.meta).to eq(options)
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

    it "returns sends message to compound document" do
      expect(compound_document).to receive(:with).with(mappers, options)
      expect(with_compound_document).to receive(:call).with(resource)

      document.compound_document
    end
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
      let(:options) { {pager: double("Pager")} }

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
      let(:options) { {pager: double("Pager")} }

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
