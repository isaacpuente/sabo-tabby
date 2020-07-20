# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/error"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Mapper::Error do
  include_context "test_data"

  let(:error_class) {
    class_double("SaboTabby::Error", new: error)
      .as_stubbed_const(transfer_nested_constants: true)
  }
  let(:error) { instance_double("SaboTabby::Error") }
  let(:error_mapper) { SaboTabby::Mapper::StandardError.new }

  before do
    stub_const("SaboTabby::Error", error_class)
  end

  describe "#initialize" do
    let(:readers) { %i(type status code title detail resource name) }
    it "sets classes settings as readers" do
      readers.each do |r|
        expect(error_mapper).to respond_to(r)
        case r
        when :name
          expect(error_mapper.send(r)).to eq(error_mapper.class.send(:resource))
        when :resource
          expect(error_mapper.send(r)).to eq(error)
        when :detail
          expect(error_mapper.send(r)).to be_a(Proc)
        when :type
          expect(error_mapper.send(r)).to eq(:standard_error)
        else
          expect(error_mapper.send(r)).to eq(error_mapper.class.send(r))
        end
      end
    end
    context "name" do
      it "sets mapper's class resource as value" do
        expect(error_mapper.name).to eq(error_mapper.class.resource)
      end
    end
    context "type" do
      context "mapper's class type has value" do
        let(:error_mapper_with_type) { ValidationErrorMapper.new }
        it "sets mapper's class type as value" do
          expect(error_mapper_with_type.type).to eq(error_mapper_with_type.class.send(:type))
        end
      end
      context "mapper's class type is nil" do
        it "sets mapper's name as value" do
          expect(error_mapper.type).to eq(error_mapper.name)
        end
      end
    end
  end
  describe "#with" do
    let(:options) { {include: [:nap_spot]} }
    it "sends given options to resource" do
      expect(error).to receive(:with).with(**options)
      error_mapper.with(**options)
    end
  end
  describe "#detail" do
    let(:standard_error) { instance_double("StandardError", message: "Standard error") }
    context "with block" do
      it "return default detail setting's block value" do
        expect(error_mapper.detail.(standard_error))
          .to eq(standard_error.message)
      end
    end
    context "without block" do
      let(:error_mapper) { WithoutBlockErrorMapper.new }
      it "return default block value" do
        expect(error_mapper.detail.(standard_error))
          .to eq(message: standard_error.message, origin: "")
      end
    end
  end
end
