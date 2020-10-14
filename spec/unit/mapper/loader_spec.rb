# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::Mapper::Loader do
  include_context "test_data"

  subject(:loader) { described_class.new(resource, resource_name, options) }
  let(:options) { {include: [:hooman, :nap_spots]} }
  let(:container) { SaboTabby::Container }
  let(:resource) { the_cat }
  let(:resource_name) { cat_mapper.name.to_s }
  let(:mappers) {
    {
      "cat" => cat_mapper,
      "hooman" => hooman_mapper,
      "nap_spot" => nap_spot_mapper,
      "sand_box" => sand_box_mapper
    }
  }

  before do
    mappers.each do |key, mapper|
      container.stub("mappers.#{key}", mapper)
    end
  end
  after do
    mappers.each do |key, _mapper|
      container.unstub("mappers.#{key}")
    end
  end

  describe "#initialize" do
    it "sets readers" do
      expect(loader.resource).to eq(resource)
      expect(loader.resource_name).to eq(resource_name)
      expect(loader.options).to eq(options)
      expect(loader.mappers).to eq({})
      expect(loader.resource_mapper).to eq(cat_mapper)
    end
  end

  describe "#init_mappers" do
    context "success" do
      it "loads resource and resource's relationship mappers" do
        expect(loader.init_mappers).to eq(loaded_mappers)
      end
      context "compound" do
        it "inlcudes compound document mappers" do
          expect(loader.init_mappers(compound: true)).to eq(loaded_mappers)
        end
      end
      context "error" do
        subject(:loader) {
          described_class.new(StandardError.new("oops"), validation_error_mapper.name.to_s, options)
        }
        before do
          container.stub("mappers.errors.validation_error", validation_error_mapper)
        end
        after do
          container.unstub("mappers.errors.validation_error")
        end
        xcontext "through options" do
          it "loads error mappers"
        end
        context "through mapper name" do
          it "loads error mappers" do
            expect(loader.init_mappers).to eq(loaded_error_mappers)
          end
        end
      end
    end
    context "failure" do
      context "unkown mapper name" do
        it "raises exception" do
          expect { described_class.new("dog", options) }.to(
            raise_error(Dry::System::ComponentLoadError, /could not load component/)
          )
        end
      end
    end
  end


  xdescribe "#mapper" do
    context "error" do
      it "returns error mapper"
    end
    it "returns resource mapper"
  end

  xdescribe "#error_mapper" do
    context "unknown mapper" do
      it "returns standard error mapper"
    end
    it "returns error mapper"
  end

  xdescribe "#relationship_mappers" do
    it "returns resrource's mapper relationship mappers"
    it "adds resrource's mapper relationship mappers to reader"
  end

  xdescribe "#compound_mappers" do
    context "options include"
    context "mapper relationship settings include"
  end

  xdescribe "#compound_path" do
    context "options include"
    context "mapper relationship settings include"
  end

  xdescribe "#error?" do
    context "true"
    context "false"
  end
end
