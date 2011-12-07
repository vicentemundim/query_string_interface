module ParseDates
  def with_parsed_dates(options)
    options.inject({}) do |result, item|
      key, value = item
      result[key] = parse_dates_in(value)
      result
    end
  end

  def parse_dates_in(value)
    if value.is_a?(Hash)
      value.inject({}) { |r, i| k, v = i; r[k] = parse_dates_in(v); r }.with_indifferent_access
    elsif value.is_a?(Array)
      value.map { |i| parse_dates_in(i) }
    elsif value.is_a?(Date) || value.is_a?(DateTime) || value.is_a?(Time)
      value.to_s
    else
      value
    end
  end
end