# frozen_string_literal: true

require "sabo_tabby/error"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Error do
  include_context "test_data"

  subject(:error) { described_class.new(error_mapper) }

  let(:error_mapper) { validation_error_mapper }
  let(:scope) { StandardError.new("Ooops") }

  describe "#initialize" do
    it "sets readers" do
      expect(error.mapper).to eq(error_mapper)
      expect(error.options).to eq({})
      expect(error.mappers).to eq({error_mapper.name => error_mapper})
    end
  end
  describe "#with" do
    let(:mappers) {
      ["obj_hash" => instance_double("StandarErrorMapper")]
    }

    it "sets mappers and options ivars" do
      with = error.with(mappers: mappers, include: [:sand_box])
      expect(with.mappers).to eq(mappers)
      expect(with.options).to eq({include: [:sand_box]})
    end
    it "returns self" do
      with = error.with(mappers: mappers, include: [:sand_box])
      expect(with).to eq(error)
    end
    context "no mappers arg" do
      it "skips setting mappers ivar" do
        with = error.with(include: [:sand_box])
        expect(with.mappers).to eq({error_mapper.name => error_mapper})
        expect(with.options).to eq({include: [:sand_box]})
      end
    end
  end
  describe "#document" do
    it "returns error document" do
      expect(error.document(scope))
        .to eq(
          detail: "Ooops Name must be filled",
          status: "422",
          title: "Validation error",
          code: "3"
        )
    end
  end
  describe "#title" do
    it "returns error title" do
      expect(error.title(scope)).to eq("Validation error")
    end
  end
  describe "#code" do
    it "returns error code" do
      expect(error.code(scope)).to eq("3")
    end
  end
  describe "#status" do
    it "returns error status" do
      expect(error.status(scope)).to eq(422)
    end
  end
  describe "#detail" do
    it "returns detail message" do
      expect(error.detail(scope)).to eq("Ooops Name must be filled")
    end
  end
  xdescribe "#source" do
    it "returns source hash"
    context "no source" do
      it "returns empty hash"
    end
  end
  describe "#code_value" do
    it "returns code value" do
      expect(error.code_value(scope)).to eq(code: "3")
    end
    context "code is  nil" do
      let(:error_mapper) { WithoutBlockErrorMapper.new }
      it "returns code value" do
        expect(error.code_value(scope)).to eq(code: "")
      end
    end
  end
end
