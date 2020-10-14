# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::Mapper::Loader do
  xdescribe "success" do
    it "initializes all resource's relationship mappers"
    context "compound" do
      xcontext "options include" do
        it "initializes all resource's relationship mappers and compound mappers"
      end
      xcontext "mappers settings include" do
        it "initializes all resource's relationship mappers and compound mappers"
      end
    end
  end
end
