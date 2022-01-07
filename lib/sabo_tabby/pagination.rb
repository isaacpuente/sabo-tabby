# frozen_string_literal: true

# auto_register: false

require "dry-initializer"
require "forwardable"

module SaboTabby
  class Pagination
    extend Forwardable
    extend Dry::Initializer
    include Dry::Core::Constants

    PAGE_LINK_MAPPING = {
      self: :current,
      last: :total_pages,
      prev: :prev_page,
      next: :next_page
    }.freeze

    param :mappers, default: proc { {} }
    param :options, default: proc { EMPTY_HASH }
    param :pagination, default: proc { _pagination }

    def_delegators :pagination, :current, :first, :last, :next_page,
                   :prev_page, :total_records, :page_size, :total_pages

    def call
      return {} if pager.nil? || pager.send(total_records).zero?

      {
        links: build_links,
        meta: {
          total: pager.send(total_records),
          pages: pager.send(total_pages)
        }
      }
    end

    def links
      return {} if pager.nil?

      build_links
    end

    def meta
      return {} if pager.nil?

      {total: pager.send(total_records), pages: pager.send(total_pages)}
    end

    def pager
      @pager ||= pagination.pager
    end

    private

    def _pagination
      if options.fetch(:pager_klass, false)
        name = "mappers.pagers.#{options[:pager_klass]}"
        mappers[options[:pager_klass]] ||= container[name].with(**options)
      else
        name = "mappers.pagers.default_pagination"
        mappers[name] ||= container[name].with(**options)
      end
    end

    def build_links
      PAGE_LINK_MAPPING.inject(first: url(1, pager.send(page_size))) do |res, (key, method_name)|
        send(method_name)
          .then do |name|
            res.merge(key => url(pager.send(name), pager.send(page_size)))
          end
      end
    end

    def url(page_number, page_size)
      path = options.fetch(:url, "http://localhost")
      return nil if page_number.nil?

      strip_page_query_params(path)
        .then { |base| "#{base}#{query_param_separator(path)}" }
        .then { |base| "#{base}page[number]=#{page_number}&page[size]=#{page_size}" }
    end

    def strip_page_query_params(path)
      pq = path.split("?")
      query_params = pq.last.split("&").reject { |p| p.match(/\Apage\[.*\]=/) }
      return pq.first if query_params.empty? || pq == query_params

      "#{pq.first}?#{query_params.join("&")}"
    end

    def query_param_separator(path)
      strip_page_query_params(path).split("?").size > 1 ? "&" : "?"
    end

    def container
      SaboTabby::Container
    end
  end
end
