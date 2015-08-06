require "active_support/json"
require "active_support/core_ext/hash/indifferent_access"

module QueryStringInterface
  NORMAL_CONDITIONAL_OPERATORS = [:exists, :gte, :gt, :lte, :lt, :ne, :size, :near, :within]
  ARRAY_CONDITIONAL_OPERATORS = [:all, :in, :nin]
  CONDITIONAL_OPERATORS = ARRAY_CONDITIONAL_OPERATORS + NORMAL_CONDITIONAL_OPERATORS
  SORTING_OPERATORS = [:asc, :desc]
  FIELD_FILTERING_OPERATORS = [:only, :except]
  OR_OPERATOR = :or

  OPERATORS = CONDITIONAL_OPERATORS + SORTING_OPERATORS + [OR_OPERATOR]

  ATTRIBUTE_REGEX = /^(.*)\.(#{(OPERATORS).join('|')})$/
  OPERATOR_REGEX = /^.*\.(#{CONDITIONAL_OPERATORS.join('|')})$/

  ORDER_BY_PARAMETER = :order_by
  PAGINATION_PARAMTERS = [:per_page, :page]
  FRAMEWORK_PARAMETERS = [:controller, :action, :format]
  CONTROL_PARAMETERS = [:disable_default_filters]
  RESERVED_PARAMETERS = FRAMEWORK_PARAMETERS + PAGINATION_PARAMTERS + [ORDER_BY_PARAMETER] + CONTROL_PARAMETERS + FIELD_FILTERING_OPERATORS

  def default_filtering_options
    {}
  end

  def default_sorting_options
    []
  end

  def default_pagination_options
    { :per_page => 12, :page => 1 }
  end

  def sorting_attributes_to_replace
    {}
  end

  def filtering_attributes_to_replace
    {}
  end

  def pagination_options(options={})
    default_pagination_options.with_indifferent_access.merge(options)
  end

  def filtering_options(options={})
    QueryStringInterface::FilterCollection.new(
      only_filtering(options),
      options.has_key?(:disable_default_filters) ? {} : default_filtering_options,
      filtering_attributes_to_replace
    ).parse
  end

  def sorting_options(options={})
    QueryStringInterface::SortingFilters.new(options, default_sorting_options, sorting_attributes_to_replace).parse
  end

  def field_filtering_options(options={})
    options = options.with_indifferent_access

    if options[:only]
      { :only => parse_array(options[:only]) }.with_indifferent_access
    elsif options[:except]
      { :except => parse_array(options[:except]) }.with_indifferent_access
    end
  end

  def only_filtering(options={})
    options.with_indifferent_access.except(*RESERVED_PARAMETERS)
  end

  private

  def parse_array(value)
    QueryStringInterface::Parsers::ArrayParser.new.parse(value)
  end
end

require "query_string_interface/version"
require "query_string_interface/helpers"
require "query_string_interface/parsers"
require "query_string_interface/filter"
require "query_string_interface/filter_collection"
require "query_string_interface/sorting_filters"
require "query_string_interface/error"
