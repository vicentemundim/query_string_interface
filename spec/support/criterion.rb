class Criterion
  attr_accessor :name, :operator

  def initialize(options)
    self.name = options[:name]
    self.operator = options[:operator]
  end
end

class Symbol
  (QueryStringInterface::CONDITIONAL_OPERATORS + [QueryStringInterface::OR_OPERATOR]).each do |operator|
    method, operator = operator
    operator = method unless operator

    define_method(method) do
      Criterion.new(:name => self, :operator => operator)
    end
  end

  def asc
    Criterion.new(:name => self, :operator => 1)
  end

  def desc
    Criterion.new(:name => self, :operator => -1)
  end
end
