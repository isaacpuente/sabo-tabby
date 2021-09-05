# frozen_string_literal: true

require "sabo_tabby/mapper/loader"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Mapper::Loader do
  include_context "test_data"

  subject(:loader) { described_class.new(resource, options) }
  let(:options) { {include: [:hooman, :nap_spots], max_depth: 1} }
  let(:container) { SaboTabby::Container }
  let(:resource) { the_cat }
  let(:resource_name) { cat_mapper.name.to_s }

  before do
    loaded_mappers.each do |key, mapper|
      container.stub("mappers.#{key}", mapper)
    end
    container.stub("mappers.errors.standard_error", standard_error_mapper)
  end
  after do
    loaded_mappers.each do |key, _mapper|
      container.unstub("mappers.#{key}")
    end
    container.unstub("mappers.errors.standard_error")
  end

  describe "#initialize" do
    it "sets readers" do
      expect(loader.resource).to eq(resource)
      expect(loader.name).to eq(resource_name)
      expect(loader.options).to eq(options)
      expect(loader.mappers).to eq(loaded_mappers)
      expect(loader.resource_mapper).to eq(cat_mapper)
      expect(loader.scope_settings).to eq(scope_settings)
      expect(loader.compound_paths).to eq(%i(hooman nap_spots))
    end
    context "error" do
      let(:resource_name) { "standard_error" }
      let(:resource) { StandardError.new("oops") }
      it "sets readers" do
        expect(loader.mappers).to eq({resource_name => standard_error_mapper})
        expect(loader.compound_paths).to eq([])
        expect(loader.scope_settings).to eq({})
      end
    end
    context "compound_path" do
      context "auto compound" do
        it "returns auto inlcude paths"
      end
      context "options include" do
        let(:options) { {include: %w(hooman.nap_spots nap_spots sand_box)} }
        it "returns input" do
          expect(loader.compound_paths).to eq(options[:include])
        end
        context "none" do
          let(:options) { {include: %w(none)} }
          it "is empty" do
            expect(loader.compound_paths).to eq([])
          end
        end
      end
    end
  end

  describe "#mappers" do
    context "success" do
      it "loads resource and resource's relationship mappers" do
        expect(loader.mappers).to eq(loaded_mappers)
      end
      context "compound" do
        it "inlcudes compound document mappers" do
          expect(loader.mappers).to eq(loaded_mappers)
        end
      end
      context "error" do
        let(:resource) { StandardError.new("oops") }

        context "through options" do
          let(:options) { {error: true} }

          it "loads error mappers" do
            expect(loader.mappers).to eq(loaded_error_mappers)
          end
        end
        context "through mapper name" do
          let(:resource) { ValidationError.new("oops") }
          before do
            container.stub("mappers.errors.validation_error", validation_error_mapper)
          end
          after do
            container.unstub("mappers.errors.validation_error")
          end
          it "loads error mappers" do
            expect(loader.mappers).to eq("validation_error" => validation_error_mapper)
          end
        end
        context "unknown mapper" do
          let(:resource_name) { "unknown_error" }
          it "returns standard error mapper" do
            expect(loader.mappers).to eq(loaded_error_mappers)
          end
        end
      end
    end
    context "failure" do
      context "unkown mapper name" do
        it "raises exception" do
          expect { described_class.new("dog", options) }.to(
            raise_error(Dry::Container::Error, /Nothing registered with the key "mappers.string/)
          )
        end
      end
    end
  end

  describe "#mapper" do
    context "error" do
      let(:options) { {error: true} }
      let(:resource) { StandardError.new("oops") }

      it "returns error mapper" do
        expect(loader.mapper).to eq(standard_error_mapper)
      end
    end
    it "returns resource mapper" do
      expect(loader.mapper).to eq(cat_mapper)
    end
  end

  describe "#error?" do
    context "options" do
      let(:options) { {error: true} }
      it "is true" do
        expect(loader.error?).to be true
      end
    end
    context "resource name" do
      let(:resource) { StandardError.new("oops") }
      it "is true" do
        expect(loader.error?).to be true
      end
    end
  end
end
