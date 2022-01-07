# frozen_string_literal: true

require "sabo_tabby/pagination"
require "sabo_tabby/mapper/default_pagination"
require "sabo_tabby/mapper/loader"

RSpec.describe SaboTabby::Pagination do
  include_context "test_data"

  subject(:pagination) { described_class.new(loader.mappers, options) }

  let(:loader) { SaboTabby::Mapper::Loader.new(the_cat, **options) }
  let(:options) { {pager: pager} }
  let(:pagination_result) {
    {
      links: {
        first: "http://localhost?page[number]=1&page[size]=20",
        last: "http://localhost?page[number]=3&page[size]=20",
        next: "http://localhost?page[number]=3&page[size]=20",
        prev: "http://localhost?page[number]=1&page[size]=20",
        self: "http://localhost?page[number]=2&page[size]=20"
      },
      meta: {pages: 3, total: 52}
    }
  }
  let(:container) { SaboTabby::Container }

  describe "#initialize" do
    it "sets readers" do
      expect(pagination.mappers).to eq(loader.mappers)
      expect(pagination.options).to eq(options)
    end
  end

  describe "#call" do
    context "success" do
      context "default pager" do
        it "returns pagination object" do
          expect(pagination.call).to eq(pagination_result)
        end
      end
      context "custom pager" do
        let(:options) { {pager_klass: :custom_pagination, pager: custom_pager} }
        it "returns pagination object" do
          expect(pagination.call).to eq(pagination_result)
        end
      end
      context "url option" do
        let(:options) { {pager: pager, url: "https://sabotabby.com/pagination"} }
        let(:url_pagination_result) {
          pagination_result[:links].each_with_object({links: {}}) do |(key, link), result|
            result[:links][key] = "#{options[:url]}?#{link.split("?").last}"
          end
        }
        it "returns pagination object" do
          expect(pagination.call).to eq(url_pagination_result.merge(meta: pagination_result[:meta]))
        end
      end
    end
    context "failure" do
      context "unkown mapper name" do
        let(:options) { {pager_klass: "unknown_pager"} }
        it "raises exception" do
          expect { pagination.call }.to(
            raise_error(Dry::Container::Error, /Nothing registered with the key "mappers.pagers.unknown_page/)
          )
        end
      end
    end
  end

  describe "#links" do
    context "default pager" do
      it "returns links hash" do
        expect(pagination.links).to eq(pagination_result[:links])
      end
    end
    context "custom pager" do
      let(:options) { {pager_klass: :custom_pagination, pager: custom_pager} }
      it "returns links hash" do
        expect(pagination.links).to eq(pagination_result[:links])
      end
    end
  end

  describe "#meta" do
    context "default pager" do
      it "returns meta hash" do
        expect(pagination.meta).to eq(pagination_result[:meta])
      end
    end
    context "custom pager" do
      let(:options) { {pager_klass: :custom_pagination, pager: custom_pager} }
      it "returns meta hash" do
        expect(pagination.meta).to eq(pagination_result[:meta])
      end
    end
  end
end
