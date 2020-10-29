# frozen_string_literal: true

RSpec.describe SaboTabby::Resource do
  include_context "test_data"

  subject(:resource) { described_class.new(mapper, options) }

  let(:mapper) { cat_mapper }

  before do
    stub_const(
      "SaboTabby::Relationship",
      class_double("SaboTabby::Relationship", new: relationship)
    )
    allow(relationship)
      .to receive(:call).with(the_cat).and_return(relationship_result[:relationships])
  end

  describe "#initialize" do
    it "sets readers" do
      expect(resource.mapper).to eq(cat_mapper)
      expect(resource.options).to eq(options)
      expect(resource.mappers).to eq({cat_mapper.name.to_s => cat_mapper})
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
      expect(resource.identifier(the_cat)).to eq(id: the_cat.id.to_s, type: cat_mapper.type.to_s)
    end
  end

  describe "#attributes" do
    it "returns defined resource attributes hash" do
      expect(resource.attributes(the_cat))
        .to eq(
          attributes: {
            age: the_cat.age,
            family: the_cat.family,
            name: the_cat.name,
            gender: "Ms. Le prr"
          }
        )
    end
    context "sparse fieldset" do
      let(:options) { {fields: {"cat" => %w(name age)}} }
      it "returns filtered attributes hash" do
        expect(resource.attributes(the_cat))
          .to eq(attributes: {name: the_cat.name, age: the_cat.age})
      end
      context "no attributes" do
        let(:options) { {fields: {"cat" => []}} }
        it "returns empty attributes hash" do
          expect(resource.attributes(the_cat)).to eq(attributes: {})
        end
      end
    end
  end

  describe "#dynamic_attributes" do
    it "returns defined resource dynamic attributes hash" do
      expect(resource.dynamic_attributes(the_cat)).to eq(gender: "Ms. Le prr")
    end
    context "sparse fieldset" do
      let(:options) { {fields: {"cat" => %w(gender)}} }
      it "returns filtered attributes hash" do
        expect(resource.dynamic_attributes(the_cat))
          .to eq(gender: "Ms. Le prr")
      end
      context "no attributes" do
        let(:options) { {fields: {"cat" => []}} }
        it "returns empty attributes hash" do
          expect(resource.dynamic_attributes(the_cat)).to eq({})
        end
      end
    end
  end

  describe "#document" do
    it "returns resource document" do
      expect(resource.document(the_cat)).to eq(
        {
          id: "2",
          type: "cat",
          meta: {code_name: :feline},
          attributes: {
            age: 9,
            family: "Domestic",
            gender: "Ms. Le prr",
            name: "Nibbler"
          }
        }.merge(relationship_result)
      )
    end
  end

  describe "#relationships" do
    it "sends message to Relationships" do
      expect(relationship).to receive(:call).with(the_cat)
      resource.relationship.(the_cat)
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
      expect(resource.meta).to eq(meta: {code_name: :feline})
    end
  end
end
