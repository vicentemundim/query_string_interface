module QueryStringInterface
  module Parsers
    class DateTimeParser
      DATE_REGEX = /^(?:\d{4}-\d{2}-\d{2}|\d{4}-\d{1,2}-\d{1,2}[T \t]+\d{1,2}:\d{2}:\d{2}(\.[0-9]*)?([ \t]*)(Z?|[-+\s]\d{2}?(:?\d{2})?))$/
      ESCAPED_ZONE_REGEX = /\s(\d{2}:\d{2})$/

      def parseable?(value, operator)
        DATE_REGEX.match(value)
      end

      def parse(value)
        value.gsub!(ESCAPED_ZONE_REGEX) { "+#{$1}" }
        begin
          Time.parse(value)
        rescue ArgumentError => e
          raise DateTimeParseError.new e
        end
      end
    end
  end
end
