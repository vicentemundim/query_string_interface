class Criterion
  attr_accessor :key, :operator

  def initialize(options)
    @key = options[:key]
    @operator = options[:operator]
  end
end

class Symbol
  QueryStringInterface::OPERATORS.each do |oper|
    m, oper = oper
    oper = m unless oper
    class_eval <<-OPERATORS
      def #{m}
        Criterion.new(:key => self, :operator => "#{oper}")
      end
    OPERATORS
  end
end