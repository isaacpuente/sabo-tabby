# frozen_string_literal: true

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
      %i(attributes meta links resource_identifier dynamic_attributes
         relationships resource name key_transformation type key_name)
    }
    it "sets classes settings as readers" do
      readers.each do |r|
        expect(mapper).to respond_to(r)
        case r
        when :name
          expect(mapper.send(r)).to eq(mapper.class.send(:resource))
        when :attributes
          expect(mapper.send(r))
            .to eq(mapper.class.send(r).each_with_object({}) { |a, res| res[a] = a })
        when :dynamic_attributes
          expect(mapper.send(r)).to eq(
            mapper.class.send(r)
              .each_with_object({}) { |(name, block), res| res[name] = [name, block] }
          )
        when :resource
          next
        when :key_transformation
          expect(mapper.send(r)).to eq :underscore
        when :type
          expect(mapper.send(r)).to eq :cat
        when :key_name
          expect(mapper.send(r)).to eq :cat
        when :relationships
          expect(mapper.send(r)).to eq(
            mapper.class.send(r).each_with_object({}) do |(name, opts), relationships|
              relationships[name] =
                opts.merge(key_name: name, type: opts[:type] && opts[:type])
            end
          )
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
          expect(mapper.type).to eq(mapper.key_name)
        end
      end
    end
    context "key transformation" do
      before do
        allow(CatMapper).to receive(:key_transformation).and_return(:camelize)
      end
      let(:inflector) { SaboTabby::Container[:inflector] }
      context "attributes" do
        it "returns transformed key names" do
          expect(mapper.attributes).to eq(
            mapper.class.attributes.each_with_object({}) do |a, res|
              res[a] = inflector.camelize(a).to_sym
            end
          )
        end
      end
      context "dynamic_attributes" do
        it "returns transformed key names" do
          expect(mapper.dynamic_attributes).to eq(
            mapper.class.dynamic_attributes.each_with_object({}) do |(name, block), res|
              res[name] = [inflector.camelize(name).to_sym, block]
            end
          )
        end
      end
      context "relationships" do
        it "returns transformed key name and type" do
          expect(mapper.relationships).to eq(
            mapper.class.relationships.each_with_object({}) do |(name, opts), relationships|
              relationships[name] =
                opts.merge(
                  key_name: inflector.camelize(name).to_sym,
                  type: opts[:type] && inflector.camelize(opts[:type])
                )
            end
          )
        end
      end
      context "key_name" do
        it "returns transformed key name" do
          expect(mapper.key_name).to eq(:Cat)
        end
      end
    end
  end
end
