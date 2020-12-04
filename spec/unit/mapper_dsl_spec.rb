# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper"

RSpec.describe SaboTabby::Mapper do
  include_context "test_data"

  describe ".inherited" do
    class LittleHooman < HoomanMapper
      include SaboTabby::Mapper
      resource :little_hooman
    end
    let(:mapper) { LittleHooman.new }

    it "initializes superclass settings first" do
      expect(mapper.type).to eq("people")
    end
    it "adds specialized settings" do
      expect(mapper.name).to eq(:little_hooman)
    end
  end

  describe ".resource" do
    let(:nested_attribute_methods) { %i(relationships) }
    let(:aliased_methods) { {attribute: :dynamic_attributes} }
    let(:dsl_methods) {
      {
        type: nil,
        attributes: [],
        attribute: [],
        relationships: {},
        meta: {}
      }
    }
    context "without arg" do
      class WithoutArgMapper
        include SaboTabby::Mapper
        resource
      end
      let(:mapper) { WithoutArgMapper }

      it "is nil" do
        expect(mapper.resource).to be_nil
      end
    end
    context "with arg" do
      let(:mapper) { SandBoxMapper }

      it "returns defined value" do
        expect(mapper.resource).to eq(:sand_box)
      end
    end
    context "without block" do
      let(:mapper) { SandBoxMapper }

      it "initializes all settings to default values" do
        dsl_methods.each do |method, value|
          case method
          when :type, :attributes, :meta
            expect(mapper.config).to respond_to("_#{method}")
            expect(mapper.config.send("_#{method}")).to eq(value)
          when :relationships
            value.each do |m, def_val|
              expect(mapper.config.send("_#{method}")).to respond_to(m)
              expect(mapper.config.send("_#{method}").send(m)).to eq(def_val)
            end
          when :attribute
            expect(mapper.config).to respond_to(:_dynamic_attributes)
            expect(mapper.config.send(:_dynamic_attributes)).to eq(value)
          end
        end
      end
    end
    context "with block" do
      let(:mapper) { CatMapper }
      let(:dsl_methods) {
        {
          type: nil,
          attributes: %i(name age family),
          attribute: [[:gender, -> {}]],
          relationships: {
            nap_spot: {method: :nap_spots, cardinality: :many},
            hooman: {method: :hooman, type: :people, cardinality: :one},
            sand_box: {method: :sand_box, cardinality: :one}
          },
          meta: {code_name: :feline}
        }
      }
      it "initializes all settings" do
        dsl_methods.each do |method, value|
          case method
          when :type, :attributes, :meta
            expect(mapper.config).to respond_to("_#{method}")
            expect(mapper.config.send("_#{method}")).to eq(value)
          when :attribute
            expect(mapper.config).to respond_to(:_dynamic_attributes)
            expect(mapper.config.send(:_dynamic_attributes)[0].first).to eq(:gender)
            expect(mapper.config.send(:_dynamic_attributes)[0].last).to be_a(Proc)
          end
        end
      end
    end
  end

  describe ".type" do
    let(:mapper) { HoomanMapper }

    it "sets type" do
      expect(mapper.type).to eq(:people)
    end
    context "not set" do
      let(:mapper) { CatMapper }

      it "is nil" do
        expect(mapper.type).to eq(nil)
      end
    end
  end
  describe ".key_transformation" do
    let(:mapper) { CatMapper }

    it "sets type" do
      allow(CatMapper).to receive(:key_transformation).and_return(:camelize)
      expect(mapper.key_transformation).to eq(:camelize)
    end
    context "not set" do
      it "is nil" do
        expect(mapper.key_transformation).to eq(nil)
      end
    end
  end

  describe ".meta" do
    let(:mapper) { HoomanMapper }

    it "sets meta" do
      expect(mapper.meta).to eq(run_by: :cats)
    end
    context "not set" do
      let(:mapper) { SandBoxMapper }

      it "is empty hash" do
        expect(mapper.meta).to eq({})
      end
    end
  end

  describe ".attributes" do
    let(:mapper) { CatMapper }

    it "sets attributes" do
      expect(mapper.attributes).to eq(%i(name age family))
    end
    context "not set" do
      let(:mapper) { SandBoxMapper }

      it "is empty hash" do
        expect(mapper.attributes).to eq([])
      end
    end
  end

  describe ".resource_identifier" do
    let(:mapper) { NapSpotMapper }

    it "sets resource identifier" do
      expect(mapper.resource_identifier).to eq(:spot_id)
    end
    context "not set" do
      let(:mapper) { SandBoxMapper }

      it "sets default resource identifier" do
        expect(mapper.resource_identifier).to eq(:id)
      end
    end
  end

  describe ".links" do
    let(:mapper) { NapSpotMapper }
    it "sets link" do
      expect(mapper.links).to eq(self: ["nap-spots", nil])
    end
    context "not set" do
      let(:mapper) { SandBoxMapper }

      it "is nil" do
        expect(mapper.links).to eq({})
      end
    end
    context "with block" do
      let(:mapper) { HoomanMapper }
      it "recieves a block" do
        expect(mapper.links[:self].last.call("http:example.com", "humans", hooman))
          .to eq("http:example.com/humans/hooman-name-1")
      end
    end
  end

  describe ".attribute" do
    let(:mapper) { CatMapper }

    it "is alias for dynamic_attributes" do
      expect(mapper.attribute).to eq(mapper.dynamic_attributes)
    end
    it "adds each attribute call to dynamic_attributes setting" do
      expect(mapper.dynamic_attributes.size).to eq(2)
    end
    it "recieves a block" do
      expect(mapper.dynamic_attributes[0].last.call(:f)).to eq("Ms. Le prr")
      expect(mapper.dynamic_attributes[1].last.call(nil, the_cat)).to eq(4)
    end
    it "adds a block as last element" do
      mapper.dynamic_attributes.each do |(*_name, block)|
        expect(block).to be_a(Proc)
      end
    end
  end
  context "relationships" do
    describe ".relationships" do
      let(:mapper) { SandBoxMapper }
      it "is defined when resource is defined" do
        expect(mapper.relationships).to eq({})
      end
    end

    describe ".one" do
      context "without options" do
        let(:mapper) { CatMapper }

        it "sets singularized method name as key and original as method option" do
          expect(mapper.relationships).to eq(
            hooman: {
              method: :hooman,
              cardinality: :one,
              links: {related: {}, self: {}}
            },
            sand_box: {method: :sand_box, cardinality: :one},
            nap_spots: {method: :nap_spots, cardinality: :many}
          )
        end
      end
      context "with options" do
        let(:mapper) { NapSpotMapper }
        context "as option" do
          it "sets singularized as option value as key and original as 'as' option" do
            expect(mapper.relationships).to eq(cat: {method: :cat, cardinality: :one})
          end
        end
      end
    end

    describe ".many" do
      context "with options" do
        let(:mapper) { HoomanMapper }
        context "as option" do
          it "sets singularized as option value as key and original as 'as' option" do
            expect(mapper.relationships).to eq(
              cats: {as: :cats, method: :babies, cardinality: :many, type: :cat},
              jobs: {cardinality: :many, method: :jobs},
              nap_spots: {method: :nap_spots, cardinality: :many}
            )
          end
        end
      end
    end
  end
end
