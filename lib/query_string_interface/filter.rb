require 'uri'
require 'json'

module QueryStringInterface
  class Filter
    include QueryStringInterface::Helpers

    attr_reader :raw_attribute, :raw_value

    PARSERS = [
      QueryStringInterface::Parsers::ArrayParser.new,
      QueryStringInterface::Parsers::DateTimeParser.new,
      QueryStringInterface::Parsers::NumberParser.new,
      QueryStringInterface::Parsers::RegexParser.new,
      QueryStringInterface::Parsers::BooleanAndNilParser.new
    ]

    def initialize(raw_attribute, raw_value, attributes_to_replace={}, raw_params={})
      @raw_attribute = raw_attribute
      @raw_value = raw_value
      @attributes_to_replace = attributes_to_replace
      @raw_params = raw_params
    end

    def attribute
      @attribute ||= replaced_attribute_name(parsed_attribute, @attributes_to_replace).to_s
    end

    def value
      @value ||= expanded_value
    end

    def operator
      @operator ||= operator_from(raw_attribute)
    end

    def or_attribute?
      raw_attribute == 'or'
    end

    def or_value
      @or_value ||= JSON.parse(raw_value) if or_attribute?
    end

    def include?(other_filter)
      if or_attribute?
        json_value.any? do |filters|
          filters.filter_parsers.any? do |filter_parser|
            filter_parser.attribute == other_filter.attribute &&
              conditional_array_operators.include?(filter_parser.operator) &&
              filter_parser.operator == other_filter.operator
          end
        end
      end
    end

    def merge(other_filter)
      if or_attribute?
        @value = json_value.map do |filters|
          filters.filter_parsers << other_filter
          filters.parse
        end
      elsif conditional_array_operators.include?(other_filter.operator) && operator == other_filter.operator
        @value = value.inject({}) do |result, filter|
          filter_operation, filter_value = filter
          filter_value = filter_value.concat(other_filter.value[filter_operation]) if other_filter.value[filter_operation]
          result[filter_operation] = filter_value
          result
        end
      elsif !operator.nil? && !other_filter.operator.nil?
        @value = value.merge(other_filter.value)
      else
        raise MixedArgumentError, "arguments `#{raw_attribute}` and `#{other_filter.raw_attribute}` could not be mixed"
      end
    end

    private
      def parsed_attribute
        if raw_attribute.respond_to?(:name)
          raw_attribute.name.to_s
        elsif or_attribute?
          '$or'
        elsif raw_attribute =~ QueryStringInterface::ATTRIBUTE_REGEX
          $1
        else
          raw_attribute
        end
      end

      def expanded_value
        if operator
          if or_attribute?
            parsed_json_value
          else
            { operator => replaced_attribute_value(parsed_attribute, parsed_value, @attributes_to_replace, @raw_params) }
          end
        else
          replaced_attribute_value(parsed_attribute, parsed_value, @attributes_to_replace, @raw_params)
        end
      end

      def parsed_value
        if raw_value.is_a?(String)
          PARSERS.each do |parser|
            return parser.parse(unescaped_raw_value) if parser.parseable?(unescaped_raw_value, operator)
          end

          return nil
        else
          raw_value
        end
      end

      def parsed_json_value
        if unescaped_raw_value.is_a?(String)
          json_value.map(&:parse)
        else
          unescaped_raw_value
        end
      end

      def json_value
        raw_or_data = disable_active_support_datetime_parsing do
          ActiveSupport::JSON.decode(unescaped_raw_value)
        end

        raise "$or query filters must be given as an array of hashes" unless valid_or_filters?(raw_or_data)

        raw_or_data.map do |filters|
          FilterCollection.new(filters, {}, @attributes_to_replace, @raw_params)
        end
      end

      def disable_active_support_datetime_parsing
        old_value = ActiveSupport.parse_json_times
        ActiveSupport.parse_json_times = false
        result = yield
        ActiveSupport.parse_json_times = old_value
        result
      end

      def valid_or_filters?(raw_or_data)
        raw_or_data.is_a?(Array) and raw_or_data.all? { |item| item.is_a?(Hash) }
      end

      def unescaped_raw_value
        @unescaped_raw_value ||= raw_value.is_a?(String) ? URI.unescape(raw_value) : raw_value
      end

      def conditional_array_operators
        QueryStringInterface::ARRAY_CONDITIONAL_OPERATORS.map { |o| "$#{o}" }
      end

      def operator_from(attribute)
        if attribute.respond_to?(:operator)
          "$#{attribute.operator}"
        elsif or_attribute?
          '$or'
        elsif attribute =~ QueryStringInterface::OPERATOR_REGEX
          "$#{$1}"
        end
      end
  end
end
