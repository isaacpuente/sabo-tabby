# frozen_string_literal: true

require "sabo_tabby/serialize"

RSpec.describe SaboTabby::Serialize do
  include_context "test_data"

  subject(:serializer) { described_class.new(resource, options) }

  let(:resource) { the_cat }

  let(:options) { {} }
  xdescribe "#as_json" do
    it "returns jsonapi document"
  end
  xdescribe "#as_hash" do
    it "returns hash in jsonapi format"
  end

  context "options validation" do
    context "correct option values" do
      let(:options) { {"include" => %w(hooman), "fields" => {"cat" => []}} }
      it "returns options with symbolized keys" do
        expect(serializer.validated_options).to eq(options.transform_keys(&:to_sym))
      end
    end
    context "wrong option values" do
      let(:options) { {"include" => {}, "fields" => []} }
      it "raises error" do
        expect { serializer.as_hash }
          .to raise_error(SaboTabby::Serialize::OptionsError)
      end
    end
  end
end
