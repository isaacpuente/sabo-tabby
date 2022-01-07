# frozen_string_literal: true

require "sabo_tabby/serialize"

RSpec.describe SaboTabby::Serialize do
  include_context "test_data"

  subject(:serializer) { described_class.new(resource, options) }

  let(:options) { {} }

  context "simple object" do
    let(:resource) { jobs.first }

    it "should return hash object representation" do
      expect(serializer.as_hash(type: :json)).to eq({data: {id: resource.id, cat_id: resource.cat_id, name: resource.name}})
    end
    it "should return serialized object representation"
  end
end
