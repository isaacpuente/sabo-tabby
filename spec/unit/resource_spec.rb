# frozen_string_literal: true

RSpec.describe SaboTabby::Resource do
  include_context "test_data"

  subject(:resource) { described_class.new(mapper, options) }

  let(:mapper) { cat_mapper }
  let(:mappers) { {cat_mapper.name.to_s => cat_mapper} }

  before do
    stub_const(
      "SaboTabby::Relationship",
      class_double("SaboTabby::Relationship", new: resource_relationship)
    )
    stub_const(
      "SaboTabby::Attribute",
      class_double("SaboTabby::Attribute", new: resource_attribute)
    )
    stub_const(
      "SaboTabby::Link",
      class_double("SaboTabby::Link", new: resource_link)
    )
    allow(resource_attribute)
      .to receive(:call)
      .with(the_cat)
      .and_return(attribute_result)
    allow(resource_relationship)
      .to receive(:call)
      .and_return(relationship_result["relationships"])
    allow(resource_link)
      .to receive(:call)
      .and_return(link_result["links"])
  end

  describe "#initialize" do
    it "sets readers" do
      expect(resource.mapper).to eq(cat_mapper)
      expect(resource.options).to eq(options)
      expect(resource.mappers).to eq(mappers)
    end
  end

  describe "#id" do
    context "default resource_identifier" do
      it "returns scope's identifier value" do
        expect(resource.id(the_cat)).to eq(the_cat.id)
      end
    end
    context "custom resource_identifier" do
      subject(:resource) { described_class.new(nap_spot_mapper, options) }
      it "returns scope's identifier value" do
        expect(resource.id(nap_spots[0])).to eq(nap_spots[0].spot_id)
      end
    end
    context "scope is an integer" do
      it "returns scope" do
        expect(resource.id(1)).to eq(1)
      end
    end
  end

  describe "#identifier" do
    it "returns idetnifier hash" do
      expect(resource.identifier(the_cat))
        .to eq("id" => the_cat.id.to_s, "type" => cat_mapper.type.to_s)
    end
  end

  describe "#attributes" do
    it "returns defined resource attributes hash" do
      expect(resource.attributes(the_cat))
        .to eq(
          "attributes" => {
            "age" => the_cat.age,
            "family" => the_cat.family,
            "name" => the_cat.name,
            "gender" => "Ms. Le prr"
          }
        )
    end
  end

  describe "#document" do
    it "returns resource document" do
      expect(resource.document(the_cat)).to eq(
        {
          "id" => "2",
          "type" => "cat",
          "meta" => {code_name: :feline},
          "attributes" => {
            "age" => 9,
            "family" => "Domestic",
            "gender" => "Ms. Le prr",
            "name" => "Nibbler"
          }
        }.merge(relationship_result)
      )
    end
  end

  describe "#relationships" do
    it "sends message to Relationships" do
      expect(resource_relationship).to receive(:call).with(the_cat)
      resource.relationships(the_cat)
    end
  end

  describe "#meta" do
    context "no meta mapper setting" do
      let(:mapper) { hooman_mapper }
      it "returns empty object" do
        expect(resource.meta).to eq({})
      end
    end
    it "returns resource meta object" do
      expect(resource.meta).to eq("meta" => {code_name: :feline})
    end
  end
end
