# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::Mapper::Loader do
  include_context "test_data"

  subject(:loader) { described_class.new(options) }
  let(:options) { {include: [:hooman, :nap_spots]} }
  let(:container) { SaboTabby::Container }
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
      allow(mapper).to receive(:with).with(**options).and_return(mapper)
    end
  end
  after do
    mappers.each do |key, _mapper|
      container.unstub("mappers.#{key}")
    end
  end

  describe ".for" do
    it "creates new instance of self and returns result from call" do
      res = described_class.for(String(cat_mapper.name), **options)
      expect(res).to eq(loaded_mappers)
    end
  end
  describe "#call" do
    context "success" do
      it "loads resource and resource's relationship mappers" do
        expect(loader.(String(cat_mapper.name))).to eq(loaded_mappers)
      end
      context "error" do
        before do
          container.stub("mappers.errors.validation_error", validation_error_mapper)
          allow(validation_error_mapper)
            .to receive(:with)
            .with(**options)
            .and_return(validation_error_mapper)
        end
        after do
          container.unstub("mappers.errors.validation_error")
        end
        xcontext "through options" do
          it "loads error mappers"
        end
        context "through mapper name" do
          it "loads error mappers" do
            expect(loader.(String(validation_error_mapper.name))).to eq(loaded_error_mappers)
          end
        end
      end
    end
    context "failure" do
      context "unkown mapper name" do
        it "raises exception" do
          expect { loader.("dog") }.to(
            raise_error(Dry::System::ComponentLoadError, /could not load component/)
          )
        end
      end
    end
  end
end
