require 'spec_helper'
require 'active_support/core_ext'

class SimpleDocument
  extend QueryStringInterface
end

class Document
  extend QueryStringInterface

  def self.default_filtering_options
    { :status => 'published' }
  end

  def self.default_sorting_options
    [:created_at.desc, :updated_at.asc]
  end

  def self.filtering_attributes_to_replace
    { :names => :tags }
  end

  def self.sorting_attributes_to_replace
    { :fullnames => :tags, :updated_at => :updated_at_sortable}
  end
end

describe QueryStringInterface do
  describe "defaults" do
    it "should return an empty hash as the default filtering options" do
      SimpleDocument.default_filtering_options.should == {}.with_indifferent_access
    end

    it "should return an empty array as the default sorting options" do
      SimpleDocument.default_sorting_options.should == []
    end

    it "should return hash with per_page => 12 and page => 1 for the default pagination options" do
      SimpleDocument.default_pagination_options.should == { :per_page => 12, :page => 1 }
    end

    it "should return an empty hash as the default sorting attributes to replace" do
      SimpleDocument.sorting_attributes_to_replace.should == {}.with_indifferent_access
    end

    it "should return an empty hash as the default filtering attributes to replace" do
      SimpleDocument.filtering_attributes_to_replace.should == {}.with_indifferent_access
    end
  end

  context 'with default filtering options' do
    it 'should use the default filtering options' do
      Document.filtering_options.should == Document.default_filtering_options.with_indifferent_access
    end
  end

  context 'with default sorting options' do
    it 'should use the default sorting options if no sorting option is given' do
      Document.sorting_options.should == [{:created_at => :desc}, {:updated_at_sortable => :asc}]
    end

    it 'should use the given order_by and ignore the default sorting options' do
      Document.sorting_options(:order_by => [{:created_at => :asc}]).should == [{:created_at => :asc}]
    end
  end

  context 'with filtering' do
    it 'should use a simple filter on a document attribute, always keeping the default filters' do
      Document.filtering_options('title' => 'Some Title').should == {:title => 'Some Title', :status => 'published'}.with_indifferent_access
    end

    it 'should use a complex filter in an embedded document attribute' do
      Document.filtering_options('embedded_document.name' => 'My Name').should == {'embedded_document.name'.to_sym => 'My Name', :status => 'published'}.with_indifferent_access
    end

    it 'should ignore pagination parameters' do
      Document.filtering_options('title' => "Some Title", 'page' => 1, 'per_page' => 20).should == {:title => 'Some Title', :status => 'published'}.with_indifferent_access
    end

    it 'should ignore order_by parameters' do
      Document.filtering_options('title' => "Some Title", 'order_by' => 'created_at').should == {:title => 'Some Title', :status => 'published'}.with_indifferent_access
    end

    it 'should ignore controller, action and format parameters' do
      Document.filtering_options('title' => "Some Title", 'controller' => 'documents', 'action' => 'index', 'format' => 'json').should == {:title => 'Some Title', :status => 'published'}.with_indifferent_access
    end

    it 'should accept simple regex values' do
      Document.filtering_options('title' => '/ome Tit/').should == {:title => /ome Tit/, :status => 'published'}.with_indifferent_access
    end

    it 'should accept regex values with modifiers' do
      Document.filtering_options('title' => '/some title/i').should ==  {:title => /some title/i, :status => 'published'}.with_indifferent_access
    end

    it 'should not raise error if empty values are used' do
      lambda { Document.filtering_options('title' => '') }.should_not raise_error
    end

    it 'should unescape all values in the URI' do
      Document.filtering_options('title' => 'Some%20Title').should == {:title => 'Some Title', :status => 'published'}.with_indifferent_access
    end

    context 'with conditional operators' do
      let :default_parameters do
        Document.default_filtering_options.inject({}) { |r, i| k, v = i; r[k.to_s] = v; r }
      end

      it 'should use it when given as the last portion of attribute name' do
        Document.filtering_options('title.ne' => 'Some Other Title').should == {:title => { "$ne" => 'Some Other Title' }, :status => 'published'}.with_indifferent_access.with_indifferent_access
      end

      it 'should accept different conditional operators for the same attribute' do
        options = Document.filtering_options('created_at.gt' => 6.days.ago.to_time.to_s, 'created_at.lt' => 4.days.ago.to_time.to_s)
        with_parsed_dates(options).should == {
          :created_at => {
            :$gt => 6.days.ago.to_time.to_s,
            :$lt => 4.days.ago.to_time.to_s
          },
          :status => 'published'
        }.with_indifferent_access
      end

      context 'with date values' do
        it 'should parse a date correctly' do
          options = Document.filtering_options('created_at' => 2.days.ago.to_time.to_s)
          with_parsed_dates(options).should == {
            :created_at => 2.days.ago.to_time.to_s,
            :status => 'published'
          }.with_indifferent_access
        end
      end

      context 'with number values' do
        it 'should parse a integer correctly' do
          Document.filtering_options('some_integer.lt' => '2').should == {
            :some_integer => { :$lt => 2 }, :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as an integer if it does not starts with a digit' do
          Document.filtering_options('embedded_document.tags' => 'H4').should == {
            :"embedded_document.tags" => "H4", :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as an integer if it does not ends with a digit' do
          Document.filtering_options('embedded_document.tags' => '4H').should == {
            :"embedded_document.tags" => "4H", :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as an integer if it has a non digit character in it' do
          Document.filtering_options('embedded_document.tags' => '4H4').should == {
            :"embedded_document.tags" => "4H4", :status => 'published'
          }.with_indifferent_access
        end

        it 'should parse a float correctly' do
          Document.filtering_options('some_float.lt' => '2.1').should == {
            :some_float => { :$lt => 2.1 }, :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as a float if it does not starts with a digit' do
          Document.filtering_options('embedded_document.tags' => 'H4.1').should == {
            :"embedded_document.tags" => "H4.1", :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as a float if it does not ends with a digit' do
          Document.filtering_options('embedded_document.tags' => '4.1H').should == {
            :"embedded_document.tags" => "4.1H", :status => 'published'
          }.with_indifferent_access
        end

        it 'should not parse as a float if it has a non digit character in it' do
          Document.filtering_options('embedded_document.tags' => '4.1H4.1').should == {
            :"embedded_document.tags" => "4.1H4.1", :status => 'published'
          }.with_indifferent_access
        end
      end

      context 'with regex values' do
        it 'should accept simple regex values' do
          Document.filtering_options('title.in' => '/ome Tit/').should == {
            :title => { :$in => [/ome Tit/] }, :status => 'published'
          }.with_indifferent_access
        end

        it 'should accept regex values with modifiers' do
          Document.filtering_options('title.in' => '/some title/i').should == {
            :title => { :$in => [/some title/i] }, :status => 'published'
          }.with_indifferent_access
        end
      end

      context 'with boolean values' do
        it 'should accept "true" string as a boolean value' do
          Document.filtering_options('some_boolean' => 'true').should == {
            :some_boolean => true, :status => 'published'
          }.with_indifferent_access
        end

        it 'should accept "false" string as a boolean value' do
          Document.filtering_options('other_boolean' => 'false').should == {
            :other_boolean => false, :status => 'published'
          }.with_indifferent_access
        end
      end

      context 'with nil value' do
        it 'should accept "nil" string as nil value' do
          Document.filtering_options('nil_value' => 'nil').should == {
            :nil_value => nil, :status => 'published'
          }.with_indifferent_access
        end
      end

      context 'with array values' do
        it 'should convert values into arrays for operator $all' do
          Document.filtering_options('tags.all' => 'basquete|futebol').should == {
            :tags => {:$all => ['basquete', 'futebol']}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should convert values into arrays for operator $in' do
          Document.filtering_options('tags.in' => 'basquete|futebol').should == {
            :tags => {:$in => ['basquete', 'futebol']}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should convert values into arrays for operator $nin' do
          Document.filtering_options('tags.nin' => 'jabulani|futebol').should == {
            :tags => {:$nin => ['jabulani', 'futebol']}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should convert single values into arrays for operator $all' do
          Document.filtering_options('tags.all' => 'basquete').should == {
            :tags => {:$all => ['basquete']}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should convert single values into arrays for operator $in' do
          Document.filtering_options('tags.in' => 'basquete').should == {
            :tags => {:$in => ['basquete']}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should convert single values into arrays for operator $nin' do
          Document.filtering_options('tags.nin' => 'jabulani').should == {
            :tags => {:$nin => ['jabulani']}, :status => 'published'
          }.with_indifferent_access
        end

        it "should properly use the $in operator when only one integer value is given" do
          Document.filtering_options("some_integer.in" => "1").should == {
            :some_integer => {:$in => [1]}, :status => 'published'
          }.with_indifferent_access
        end

        it "should properly use the $in operator when only one float value is given" do
          Document.filtering_options("some_float.in" => "1.1").should == {
            :some_float => {:$in => [1.1]}, :status => 'published'
          }.with_indifferent_access
        end

        it "should properly use the $in operator when only one date time value is given" do
          with_parsed_dates(Document.filtering_options("created_at.in" => Time.now.iso8601)).should == {
            :created_at => {:$in => [Time.now.iso8601]}, :status => 'published'
          }.with_indifferent_access
        end

        it 'should accept different conditional operators for the same attribute' do
          Document.filtering_options('tags.all' => 'esportes|basquete', 'tags.nin' => 'rede globo|esporte espetacular').should == {
            :tags => {:$all => ['esportes', 'basquete'], :$nin => ['rede globo', 'esporte espetacular']}, :status => 'published'
          }.with_indifferent_access
        end
      end

      context "with 'or' attribute" do
        it "should accept a json with query data" do
          Document.filtering_options('or' => '[{"tags.all": "flamengo|basquete"}, {"tags.all": "flamengo|jabulani"}]').should == {
            :$or => [
              {:tags => { :$all => ['flamengo', 'basquete'] }},
              {:tags => { :$all => ['flamengo', 'jabulani'] }}
            ],
            :status => 'published'
          }.with_indifferent_access
        end

        it "should unescape the json" do
          Document.filtering_options('or' => '[{"tags.all":%20"flamengo%7Cbasquete"},%20{"tags.all":%20"flamengo%7Cjabulani"}]').should == {
            :$or => [
              {:tags => { :$all => ['flamengo', 'basquete'] }},
              {:tags => { :$all => ['flamengo', 'jabulani'] }}
            ],
            :status => 'published'
          }.with_indifferent_access
        end

        it "should accept any valid query" do
          Document.filtering_options('or' => '[{"tags.all": ["flamengo", "basquete"]}, {"tags": {"$all" : ["flamengo", "jabulani"]}}]').should == {
            :$or => [
              {:tags => { :$all => ['flamengo', 'basquete'] }},
              {:tags => { :$all => ['flamengo', 'jabulani'] }}
            ],
            :status => 'published'
          }.with_indifferent_access
        end

        context "when ActiveSupport.parse_json_times is enabled" do
          before { ActiveSupport.parse_json_times = true }
          after  { ActiveSupport.parse_json_times = false }

          it "should properly convert dates" do
            Document.filtering_options('or' => '[{"created_at.gte": "2010-01-01"}, {"created_at.lt": "2010-02-15"}]').should == {
              :$or => [
                {:created_at => { :$gte => Time.parse("2010-01-01") }},
                {:created_at => { :$lt => Time.parse("2010-02-15") }}
              ],
              :status => 'published'
            }.with_indifferent_access
          end

          it "should leave ActiveSupport.parse_json_times with the old value" do
            Document.filtering_options('or' => '[{"created_at.gte": "2010-01-01"}, {"created_at.lt": "2010-02-15"}]')
            ActiveSupport.parse_json_times.should be_true

            ActiveSupport.parse_json_times = false
            Document.filtering_options('or' => '[{"created_at.gte": "2010-01-01"}, {"created_at.lt": "2010-02-15"}]')
            ActiveSupport.parse_json_times.should be_false
          end
        end

        context "with other parameters outside $or" do
          context "that use array conditional operators" do
            context "with single values" do
              it "should merge outside parameters into $or clauses" do
                Document.filtering_options('tags.all' => 'flamengo', 'or' => '[{"tags.all": ["basquete"]}, {"tags.all" : ["jabulani"]}]').should == {
                  :$or => [
                    {:tags => { :$all => ['basquete', 'flamengo'] }},
                    {:tags => { :$all => ['jabulani', 'flamengo'] }}
                  ],
                  :status => 'published'
                }.with_indifferent_access
              end
            end
          end
        end
      end

      context "when disabling default filtering options" do
        it "should use only the outside parameters" do
          Document.filtering_options('tags.all' => 'flamengo', :disable_default_filters => nil).should == {
            :tags => { :$all => ['flamengo'] }
          }.with_indifferent_access
        end
      end

      context "when replace attributes for filtering" do
        it "should use the replace attribute for the outside parameters" do
          Document.filtering_options('names' => 'flamengo').should == {
            :tags => 'flamengo',
            :status => 'published'
          }.with_indifferent_access
        end

        it "should use the replace attribute for parameters with modifiers" do
          Document.filtering_options('names.all' => 'flamengo').should == {
            :tags => { :$all => ['flamengo'] },
            :status => 'published'
          }.with_indifferent_access
        end

        it "should use the replace attribute for parameters with modifiers merging with outside parameters into $or clauses" do
          Document.filtering_options('tags.all' => 'flamengo', 'or' => '[{"names.all": ["basquete"]}, {"names.all" : ["jabulani"]}]').should == {
            :$or => [
              {:tags => { :$all => ['basquete', 'flamengo'] }},
              {:tags => { :$all => ['jabulani', 'flamengo'] }}
            ],
            :status => 'published'
          }.with_indifferent_access
        end
      end
    end
  end

  context "with sorting" do
    it "should only use parameters given in the order_by param" do
      Document.sorting_options('order_by' => 'tags.desc', 'tags.all' => 'flamengo').should == [{:tags => :desc}]
    end

    it "should accept more than one field with its direction in the order_by param" do
      Document.sorting_options('order_by' => 'tags.desc|exhibited_at|hits.desc', 'tags.all' => 'flamengo').should == [{:tags => :desc}, {:exhibited_at => :asc}, {:hits => :desc}]
    end

    context "when replacing attributes for sorting" do
      it "should use the replace attribute for the outside parameters" do
        Document.sorting_options('order_by' => 'fullnames').should == [{:tags => :asc}]
      end

      it "should use the replace attribute for the outside parameters with modifiers" do
        Document.sorting_options('order_by' => 'fullnames.desc').should == [{:tags => :desc}]
      end

      it "should use the replace attribute for the default sorting parameters with modifiers" do
        Document.sorting_options('tags.all' => 'flamengo').should == [{:created_at => :desc}, {:updated_at_sortable => :asc}]
      end
    end
  end

  context "with pagination" do
    it "should use the default pagination options if it is not given" do
      Document.pagination_options.should == Document.default_pagination_options.with_indifferent_access
    end

    it "should use the given options merged with the default pagination options" do
      Document.pagination_options(:page => 3).should == Document.default_pagination_options.merge(:page => 3).with_indifferent_access
    end
  end
end
