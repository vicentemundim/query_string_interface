module QueryStringInterface
  class SortingFilters
    include QueryStringInterface::Helpers

    SORTING_FIELD_REGEXP = /(.*)\.(#{QueryStringInterface::SORTING_OPERATORS.join('|')})/

    def initialize(raw_filters, default_filters, attributes_to_replace={})
      @raw_filters = raw_filters.with_indifferent_access
      @default_filters = default_filters
      @attributes_to_replace = attributes_to_replace
    end

    def parse
      if @raw_filters.has_key?('order_by')
        parse_filters(@raw_filters['order_by'])
      else
        parse_filters(@default_filters)
      end
    end

    def parse_filters(filters)
      filters = filters.split('|') if filters.is_a?(String)
      filters.map do |filter|
        replace(filter)
      end
    end

    private
      def replace(filter)
        if filter.respond_to?(:key) && filter.respond_to?(:operator)
          replaced_item_for filter.key, filter.operator
        elsif filter.is_a?(String) or filter.is_a?(Symbol)
          if match = matches?(filter)
            replaced_item_for match[1], match[2]
          else
            replaced_item_for filter, :asc
          end
        elsif filter.is_a?(Hash)
          replaced_item_for filter.keys.first, filter[filter.keys.first]
        end
      end

      def replaced_item_for(key, value)
        { replace_attribute(key, @attributes_to_replace).to_sym => value.to_sym }
      end

      def matches?(filter)
        filter.match(SORTING_FIELD_REGEXP)
      end
  end
end