# Overview ![alt build status](https://secure.travis-ci.org/vicentemundim/query_string_interface.png "Build Status")

### About QueryStringInterace

This gem extracts params given as a hash to structured data, that can be used when creating queries

### Repository

http://github.com/vicentemundim/query_string_interface

## Installing

This is a gem, so you can install it by:

    sudo gem install query_string_interface

Or, if you are using rails, put this in your Gemfile:

    gem 'query_string_interface'

## Usage

To use it, just extend QueryStringInterface in your document model:

    class Document
      include Mongoid::Document
      extend QueryInterfaceString

      # ... add fields here
    end

Then, you can use some class methods with your ORM syntax:

    def self.filter_by(params)
      where(filtering_options(params)).order_by(*sorting_options(params))
    end

# ORM Adapters

http://github.com/vicentemundim/mongoid_query_string_interface

# Credits

- Vicente Mundim: vicente.mundim at gmail dot com
- Wandenberg Peixoto: wandenberg at gmail dot com
