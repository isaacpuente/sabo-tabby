# frozen_string_literal: true

require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::Mapper::Loader do
  include_context "test_data"

  subject(:loader) { described_class.new(resource, options) }

  let(:options) { {} }
  let(:container) { SaboTabby::Container }
  let(:resource) { the_cat }
  let(:resource_mapper) { CatMapper.new }
  let(:const) {
    -> key {  Object.const_get("#{key.to_s.split("_").map(&:capitalize).join("")}Mapper") }
  }

  describe "success" do
    context "mappers" do
      it "initializes all resource's relationship mappers" do
        keys = %i(cat hooman sand_box nap_spot)
        expect(loader.mappers.keys).to eq(keys)
        keys.each do |key|
          expect(loader.mappers[key]).to be_a(const.(key))
        end
      end
      context "compound" do
        let(:options) { {include: %w(hooman nap_spots)} }
        it "initializes all resource's relationship mappers and compound mappers" do
          keys = %i(cat hooman sand_box nap_spot job)
          expect(loader.mappers.keys).to eq(keys)
          keys.each do |key|
            expect(loader.mappers[key]).to be_a(const.(key))
          end
        end
      end
      context "auto compound" do
        let(:resource) { project }
        let(:resource_mapper) { ProjectMapper.new }

        it "initializes all mappers" do
          keys = %i(project project_type user asset tag role)
          expect(loader.mappers.keys).to eq(keys)
          keys.each do |key|
            expect(loader.mappers[key]).to be_a(const.(key))
          end
        end
        context "options include" do
          let(:options) { {include: %w(project.assets)} }
          it "initializes included mappers" do
            keys = %i(project project_type user asset tag)
            expect(loader.mappers.keys).to eq(keys)
            keys.each do |key|
              expect(loader.mappers[key]).to be_a(const.(key))
            end
          end
        end
      end
    end

    context "scope_settings" do
      it "returns settings based on given scope for default max_depth" do
        expect(loader.scope_settings).to eq(scope_settings)
      end
      context "max depth" do
        let(:options) { {max_depth: 3} }

        it "returns settings based on given scope for given max_depth" do
          expect(loader.scope_settings).to eq(custom_scope_settings)
        end
      end
      context "auto compound" do
        let(:resource) { project }
        let(:resource_mapper) { ProjectMapper.new }

        it "returns settings based on given scope" do
          expect(loader.scope_settings).to eq(auto_compound_scope_settings)
        end
      end
    end

    context "compound paths" do
      context "options include" do
        let(:options) { {include: [:hooman, :nap_spots]} }
        it "return given include paths" do
          expect(loader.compound_paths).to eq(options[:include])
        end
      end
      context "auto compound" do
        let(:resource) { project }
        let(:resource_mapper) { ProjectMapper.new }
        it "return autocompund_paths" do
          expect(loader.compound_paths)
            .to eq(%w(project_type users.role users.projects assets.tags tags))
        end
        context "options include" do
          let(:options) { {include: %w(project_type assets)} }
          it "retuns given include paths" do
            expect(loader.compound_paths).to eq(options[:include])
          end
        end
      end
    end
  end
  context "failure" do
    context "unkown mapper name" do
      it "raises exception" do
        expect { described_class.new("dog", options) }.to(
          raise_error(Dry::Container::Error, /Nothing registered with the key "mappers.string/)
        )
      end
    end
  end
end
