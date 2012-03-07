module QueryStringInterface
  module Parsers
    class RegexParser
      def parseable?(value, operator)
        value =~ /^\/(.*)\/(i|m|x)?$/
      end

      def parse(value)
        if value =~ /^\/(.*)\/(i|m|x)?$/
          Regexp.new $1, $2
        end
      end
    end
  end
end
