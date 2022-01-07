# frozen_string_literal: true

require "sabo_tabby/error"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Error do
  include_context "test_data"

  subject(:error) { described_class.new(error_mapper) }

  let(:error_mapper) { SaboTabby::Mapper::StandardError.new }
  let(:scope) { StandardError.new("Ooops") }

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
              detail: "Ooops",
              status: "400",
              title: "Error",
              code: "",
            }
          ]
        )
    end
  end
  describe "#title" do
    it "returns error title" do
      expect(error.title(scope)).to eq("Error")
    end
  end
  describe "#code" do
    it "returns error code" do
      expect(error.code(scope)).to eq("")
    end
  end
  describe "#status" do
    it "returns error status" do
      expect(error.status(scope)).to eq(400)
    end
  end
  describe "#detail" do
    it "returns detail message" do
      expect(error.detail(scope)).to eq(["Ooops"])
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
      expect(error.code_value(scope)).to eq(code: "")
    end
    context "code is  nil" do
      let(:error_mapper) { WithoutBlockErrorMapper.new }
      it "returns code value" do
        expect(error.code_value(scope)).to eq(code: "")
      end
    end
  end
end
