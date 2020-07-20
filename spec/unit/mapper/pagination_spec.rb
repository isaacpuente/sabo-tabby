# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/pagination"
require "sabo_tabby/mapper/default_pagination"

RSpec.describe SaboTabby::Mapper::Pagination do
  include_context "test_data"

  let(:pagination) { SaboTabby::Mapper::DefaultPagination.new(**options) }
  let(:pager) { double("Pager") }
  let(:options) { {pager: pager} }

  describe "#initialize" do
    let(:readers) {
      %i(current first last next_page prev_page page_size total_pages total_records pager)
    }

    it "sets classes settings as readers" do
      readers.each do |r|
        expect(pagination).to respond_to(r)
        case r
        when :pager
          expect(pagination.send(r)).to eq(pager)
        else
          expect(pagination.send(r)).to eq(pagination.class.send(r))
        end
      end
    end
  end

  describe "#with" do
    it "returns new instance" do
      result = pagination.with(pager: nil)
      expect(result.class).to eq(pagination.class)
      expect(result).not_to eq(pagination)
    end
  end
end
