# frozen_string_literal: true

require "sabo_tabby/error"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Error do
  include_context "test_data"

  subject(:error) { described_class.new(error_mapper) }

  let(:error_mapper) { validation_error_mapper }
  let(:scope) { instance_double("StandardError", message: "Ooops") }

  describe "#initialize" do
    it "sets readers" do
      expect(error.mapper).to eq(error_mapper)
      expect(error.options).to eq({})
      expect(error.mappers).to eq({error_mapper.name => error_mapper})
    end
  end
  describe "#document" do
    it "returns error document" do
      expect(error.document(scope))
        .to eq(
          [
            {
              detail: "Ooops Name must be filled",
              status: "422",
              title: "Validation error",
              code: "3",
              source: {pointer: "/data/origin"}
            }
          ]
      )
    end
    context "without source" do
      let(:error_mapper) { standard_error_mapper }
      it "returns error document" do
        expect(error.document(scope))
          .to eq(
            [
              {
                detail: "Ooops User must exist.",
                status: "400",
                title: "Error",
                code: "4"
              }
            ]
          )
      end
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
      expect(error.detail(scope)).to eq(["Ooops Name must be filled"])
    end
  end
  describe "#source" do
    context "origin is nil" do
      it "returns empty source object" do
        expect(error.source(nil)).to eq({})
      end
    end
    it "returns source object"
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
