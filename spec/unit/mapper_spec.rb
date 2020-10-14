# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper"

RSpec.describe SaboTabby::Mapper do
  include_context "test_data"

  let(:resource_class) {
    class_double("SaboTabby::Resource", new: resource)
      .as_stubbed_const(transfer_nested_constants: true)
  }
  let(:resource) { instance_double("SaboTabby::Resource") }
  let(:mapper) { CatMapper.new }

  before do
    stub_const("SaboTabby::Resource", resource_class)
  end

  describe "#initialize" do
    let(:readers) {
      %i(attributes meta link resource_identifier dynamic_attributes relationships resource name)
    }
    it "sets classes settings as readers" do
      readers.each do |r|
        expect(mapper).to respond_to(r)
        case r
        when :name
          expect(mapper.send(r)).to eq(mapper.class.send(:resource))
        when :resource
          expect(mapper.send(r)).to eq(resource)
        else
          expect(mapper.send(r)).to eq(mapper.class.send(r))
        end
      end
    end
    context "name" do
      it "sets mapper's class resource as value" do
        expect(mapper.name).to eq(mapper.class.resource)
      end
    end
    context "type" do
      context "mapper's class type has value" do
        let(:mapper_with_type) { HoomanMapper.new }
        it "sets mapper's class type as value" do
          expect(mapper_with_type.type).to eq(mapper_with_type.class.send(:type))
        end
      end
      context "mapper's class type is nil" do
        it "sets mapper's name as value" do
          expect(mapper.type).to eq(mapper.name)
        end
      end
    end
  end

  describe "#resource"
  describe "#compound_relationships"
end
