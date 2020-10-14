# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/pagination"
require "sabo_tabby/mapper/default_pagination"

RSpec.describe SaboTabby::Mapper::Pagination do
  include_context "test_data"

  let(:pagination) { SaboTabby::Mapper::DefaultPagination }
  let(:custom_pagination) { CustomPaginationMapper }

  describe ".resource" do
    let(:dsl_methods) {
      {
        current: :current_page,
        first: :first_in_page,
        last: :last_in_page,
        next_page: :next_page,
        prev_page: :prev_page,
        page_size: :per_page,
        total_pages: :total_pages,
        total_records: :total
      }
    }

    context "without arg" do
      let(:pagination) {  WithoutArgPaginationMapper }
      it "is nil" do
        expect(pagination.resource).to be_nil
      end
    end
    context "with arg" do
      it "returns defined value" do
        expect(pagination.resource).to eq(:default_pagination)
      end
    end
    context "without block" do
      it "initializes all settings to default values" do
        dsl_methods.each do |method, value|
          expect(pagination.config).to respond_to("_#{method}")
          expect(pagination.config.send("_#{method}")).to eq(value)
        end
      end
    end
    context "with block" do
      let(:dsl_methods) {
        {
          current: :this_page,
          first: :first,
          last: :last,
          next_page: :next,
          prev_page: :prev,
          page_size: :page_size,
          total_pages: :pages,
          total_records: :total_records
        }
      }

      it "initializes all settings to default values" do
        dsl_methods.each do |method, value|
          expect(custom_pagination.config).to respond_to("_#{method}")
          expect(custom_pagination.config.send("_#{method}")).to eq(value)
        end
      end
    end
  end

  describe ".current" do
    it "sets current" do
      expect(custom_pagination.current).to eq(:this_page)
    end
    context "not set" do
      it "sets default title" do
        expect(pagination.current).to eq(:current_page)
      end
    end
  end

  describe ".first" do
    it "sets first " do
      expect(custom_pagination.first).to eq(:first)
    end
    context "not set" do
      it "sets default title" do
        expect(pagination.first).to eq(:first_in_page)
      end
    end
  end

  describe ".last" do
    it "sets first " do
      expect(custom_pagination.last).to eq(:last)
    end
    context "not set" do
      it "sets default title" do
        expect(pagination.last).to eq(:last_in_page)
      end
    end
  end

  describe ".next_page" do
    it "sets next_page" do
      expect(custom_pagination.next_page).to eq(:next)
    end
    context "not set" do
      it "sets default next_page" do
        expect(pagination.next_page).to eq(:next_page)
      end
    end
  end

  describe ".prev_page" do
    it "sets prev_page" do
      expect(custom_pagination.prev_page).to eq(:prev)
    end
    context "not set" do
      it "sets default prev_page" do
        expect(pagination.prev_page).to eq(:prev_page)
      end
    end
  end

  describe ".page_size" do
    it "sets page size" do
      expect(custom_pagination.page_size).to eq(:page_size)
    end
    context "not set" do
      it "sets default page size" do
        expect(pagination.page_size).to eq(:per_page)
      end
    end
  end

  describe ".total_pages" do
    it "sets total pages" do
      expect(custom_pagination.total_pages).to eq(:pages)
    end
    context "not set" do
      it "sets default total pages" do
        expect(pagination.total_pages).to eq(:total_pages)
      end
    end
  end

  describe ".total_records" do
    it "sets total_records" do
      expect(custom_pagination.total_records).to eq(:total_records)
    end
    context "not set" do
      it "sets default total records" do
        expect(pagination.total_records).to eq(:total)
      end
    end
  end
end
