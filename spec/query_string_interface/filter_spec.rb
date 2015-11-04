require 'spec_helper'
require 'active_support/core_ext'

describe QueryStringInterface::Filter do
  describe "simple filters" do
    subject do
      described_class.new('title', 'Some Title')
    end

    it "should return the raw attribute as attribute" do
      subject.attribute.should eq(subject.raw_attribute)
    end

    it "should return the raw value as it received" do
      subject.raw_value.should eq('Some Title')
    end

    it "should return the raw value as value" do
      subject.value.should eq(subject.raw_value)
    end

    context "with escaped values" do
      subject do
        described_class.new('title', URI.escape('Some Title +D'))
      end

      it "should unescape value" do
        subject.value.should eq('Some Title +D')
      end
    end

    context "with non-string values" do
      subject do
        described_class.new('date', Date.current)
      end

      it "should return the raw value as value" do
        subject.value.should eq(subject.raw_value)
      end
    end

    context "with integer values" do
      subject do
        described_class.new("count", "1234")
      end

      it "should convert value to integer" do
        subject.value.should eq(1234)
      end
    end

    context "with float values" do
      subject do
        described_class.new("count", "1234.5678")
      end

      it "should convert value to float" do
        subject.value.should eq(1234.5678)
      end
    end

    context "with date values" do
      let :date do
        2.days.ago.to_date
      end

      subject do
        described_class.new("date", date)
      end

      it "should convert value to date" do
        subject.value.should eq(date)
      end
    end

    context "with datetime values" do
      let :datetime do
        2.days.ago.to_datetime
      end

      subject do
        described_class.new("datetime", datetime)
      end

      it "should convert value to datetime" do
        subject.value.should eq(datetime)
      end
    end

    context "with time values" do
      let :time do
        2.days.ago.to_time
      end

      subject do
        described_class.new("time", time)
      end

      it "should convert value to time" do
        subject.value.should eq(time)
      end
    end

    context "with boolean values" do
      subject do
        described_class.new("boolean", 'true')
      end

      it "should convert value to boolean" do
        subject.value.should eq(true)
      end
    end

    context "with nil values" do
      subject do
        described_class.new("nil_value", 'nil')
      end

      it "should convert value to nil" do
        subject.value.should eq(nil)
      end
    end

    context "with regex values" do
      subject do
        described_class.new("regex", '/some_regex/i')
      end

      it "should convert value to regex" do
        subject.value.should eq(/some_regex/i)
      end
    end
  end

  describe "nested filters" do
    subject do
      described_class.new('program.channel.title', 'Some Title')
    end

    it "should return the raw attribute as attribute" do
      subject.attribute.should eq(subject.raw_attribute)
    end

    it "should return the raw value as value" do
      subject.value.should eq(subject.raw_value)
    end
  end

  describe "conditional filters" do
    context "with $or operator" do
      subject do
        described_class.new("or", '[{"title": "Some Title"}, {"title": "Some Other Title"}]')
      end

      it "should return $or as attribute" do
        subject.attribute.should eq('$or')
      end

      it "should parse the value as a JSON" do
        subject.value.should eq([{ 'title' => 'Some Title' }, { 'title' => 'Some Other Title' }])
      end

      context "with invalid filters" do
        subject do
          described_class.new("or", '{"title": "Some Title"}')
        end

        it "should raise error" do
          expect { subject.value }.to raise_error
        end
      end

      context "with escaped values" do
        subject do
          described_class.new("or", URI.escape('[{"title": "Some Title +D"}, {"title": "Some Other Title +D"}]'))
        end

        it "should unescape value" do
          subject.value.should eq([{ 'title' => 'Some Title +D' }, { 'title' => 'Some Other Title +D' }])
        end
      end

      context "with non-string values" do
        subject do
          described_class.new("or", [{ 'title' => 'Some Title' }, { 'title' => 'Some Other Title' }])
        end

        it "should return the raw value as value" do
          subject.value.should eq(subject.raw_value)
        end
      end

      context "with filters" do
        subject do
          described_class.new("or", '[{"title": "Some Title"}, {"count.gte": "1", "count.lt": "10"}, {"tags.all": "Some tag|Other tag", "tags.nin": ["A tag", "Another tag"]}]')
        end

        it "should parse each of the $or filters" do
          subject.value.should eq([{'title' => 'Some Title'}, {'count' => { '$gte' => 1, '$lt' => 10 }}, {'tags' => { '$all' => ['Some tag', 'Other tag'], '$nin' => ["A tag", "Another tag"] }}])
        end
      end
    end

    QueryStringInterface::NORMAL_CONDITIONAL_OPERATORS.each do |operator|
      context "with normal operator $#{operator}" do
        subject do
          described_class.new("title.#{operator}", 'Some Title')
        end

        it "should return only the field name as attribute" do
          subject.attribute.should eq('title')
        end

        it "should use the operator with value as value" do
          subject.value.should eq({ "$#{operator}" => 'Some Title' })
        end

        context "with escaped values" do
          subject do
            described_class.new("title.#{operator}", URI.escape('Some Title +D'))
          end

          it "should unescape value" do
            subject.value.should eq({ "$#{operator}" => 'Some Title +D' })
          end
        end

        context "with non-string values" do
          subject do
            described_class.new("date.#{operator}", Date.current)
          end

          it "should return the raw value as value" do
            subject.value.should eq({ "$#{operator}" => subject.raw_value })
          end
        end

        context "with integer values" do
          subject do
            described_class.new("count.#{operator}", "1234")
          end

          it "should convert value to integer" do
            subject.value.should eq({ "$#{operator}" => 1234 })
          end
        end

        context "with float values" do
          subject do
            described_class.new("count.#{operator}", "1234.5678")
          end

          it "should convert value to float" do
            subject.value.should eq({ "$#{operator}" => 1234.5678 })
          end
        end

        context "with date values" do
          let :date do
            2.days.ago.to_date
          end

          subject do
            described_class.new("date.#{operator}", date)
          end

          it "should convert value to date" do
            subject.value.should eq({ "$#{operator}" => date })
          end
        end

        context "with datetime values" do
          let :datetime do
            2.days.ago.to_datetime
          end

          subject do
            described_class.new("datetime.#{operator}", datetime)
          end

          it "should convert value to datetime" do
            subject.value.should eq({ "$#{operator}" => datetime })
          end
        end

        context "with time values" do
          let :time do
            2.days.ago.to_time
          end

          subject do
            described_class.new("time.#{operator}", time)
          end

          it "should convert value to time" do
            subject.value.should eq({ "$#{operator}" => time })
          end
        end

        context "with boolean values" do
          subject do
            described_class.new("boolean.#{operator}", 'true')
          end

          it "should convert value to boolean" do
            subject.value.should eq({ "$#{operator}" => true })
          end
        end

        context "with nil values" do
          subject do
            described_class.new("nil_value.#{operator}", 'nil')
          end

          it "should convert value to nil" do
            subject.value.should eq({ "$#{operator}" => nil })
          end
        end

        context "with regex values" do
          subject do
            described_class.new("regex.#{operator}", '/some_regex/i')
          end

          it "should convert value to regex" do
            subject.value.should eq({ "$#{operator}" => /some_regex/i })
          end
        end
      end
    end

    QueryStringInterface::ARRAY_CONDITIONAL_OPERATORS.each do |operator|
      context "with array operator $#{operator}" do
        context "with a single value" do
          subject do
            described_class.new("tags.#{operator}", 'Some Value')
          end

          it "should return the field name as attribute" do
            subject.attribute.should eq('tags')
          end

          it "should return the value as an array, using the operator" do
            subject.value.should eq({ "$#{operator}" => ['Some Value'] })
          end
        end

        context "with escaped values" do
          subject do
            described_class.new("tags.#{operator}", URI.escape('Some Value|Some Other Value|Another value +D'))
          end

          it "should unescape values" do
            subject.value.should eq({ "$#{operator}" => ['Some Value', 'Some Other Value', 'Another value +D'] })
          end
        end

        context "with multiple values separated by '|'" do
          subject do
            described_class.new("tags.#{operator}", 'Some Value|Some Other Value|Another value')
          end

          it "should return the field name as attribute" do
            subject.attribute.should eq('tags')
          end

          it "should return the value as an array" do
            subject.value.should eq({ "$#{operator}" => ['Some Value', 'Some Other Value', 'Another value'] })
          end
        end
      end
    end
  end

  describe "include?" do
    describe "or filters" do
      subject do
        described_class.new("or", '[{"title": "Some Title"}, {"count.gte": "1", "count.lt": "10"}, {"tags.all": "Some tag|Other tag", "tags.nin": ["A tag", "Another tag"]}]')
      end

      let :other_filter do
        described_class.new("tags.all", 'Other filter tag')
      end

      it "should include other filter if they have an array conditional operator and their attribute is used in one of the or clauses" do
        subject.should include(other_filter)
      end

      it "should merge other filter if they have an array conditional operator and their attribute is used in one of the or clauses" do
        subject.merge(other_filter).should eq([{'title' => 'Some Title', 'tags' => {'$all' => ['Other filter tag']}}, {'count' => { '$gte' => 1, '$lt' => 10 }, 'tags' => {'$all' => ['Other filter tag']}}, {'tags' => { '$all' => ['Some tag', 'Other tag', 'Other filter tag'], '$nin' => ["A tag", "Another tag"] }}])
      end

      it "should not merge other filter if it does not have an operator" do
        expect { subject.merge(described_class.new('tags', 'Problem tag')) }.to raise_error(QueryStringInterface::MixedArgumentError, "arguments `tags.all` and `tags` could not be mixed")
      end
    end

    describe "normal filters" do
      subject do
        described_class.new("tags.all", 'Some Value|Some Other Value|Another value')
      end

      let :other_filter do
        described_class.new("tags.all", 'Some tag')
      end

      it "should not include other filters" do
        subject.should_not include(other_filter)
      end
    end
  end

  describe "replace attribute and value" do

    let :attributes_to_replace do
      {:names => :tags}
    end

    let :attributes_to_replace_with_hash do
      {
        :names => {:to => :tags_downcase, :convert_value_to => Proc.new { |v| v.map{ |value| value.downcase } } },
        :status => {:to => :status_for_product, :convert_value_to => Proc.new { |v, raw_params| v == 'published' && raw_params[:product_id] != nil ? "published_for_product" : v } }
      }
    end

    it "should replace the raw attribute for the one in the hash parameter attributes_to_replace" do
      instance = described_class.new("names.all", 'Some Value|Some Other Value|Another value', attributes_to_replace)
      instance.attribute.should eq("tags")
    end

    it "should replace the raw attribute for the one in the hash parameter attributes_to_replace, using the :to key" do
      instance = described_class.new("names.all", 'Some Value|Some Other Value|Another value', attributes_to_replace_with_hash)
      instance.attribute.should eq("tags_downcase")
    end

    it "should use the raw value if attributes_to_replace does not have a hash for this attribute" do
      instance = described_class.new("names.all", 'Some Value|Some Other Value|Another value', attributes_to_replace)
      instance.value.should eq({ "$all" => ['Some Value', 'Some Other Value', 'Another value'] })
    end

    it "should replace the raw value for the result of given proc in the :convert_value_to key" do
      instance = described_class.new("names.all", 'Some Value|Some Other Value|Another value', attributes_to_replace_with_hash)
      instance.value.should eq({ "$all" => ['some value', 'some other value', 'another value'] })
    end

    it "should replace the raw value for the result of given proc in the :convert_value_to key, using other given params" do
      instance = described_class.new("status", 'published', attributes_to_replace_with_hash, {:product_id => 1})
      instance.value.should eq('published_for_product')
    end

    context "when attribute is an object that responds to key and operator methods" do
      it "should replace the raw attribute for the one in the hash parameter attributes_to_replace" do
        instance = described_class.new(:names.all, 'Some Value|Some Other Value|Another value', attributes_to_replace)
        instance.attribute.should eq("tags")
      end

      it "should replace the raw attribute for the one in the hash parameter attributes_to_replace, using the :to key" do
        instance = described_class.new(:names.all, 'Some Value|Some Other Value|Another value', attributes_to_replace_with_hash)
        instance.attribute.should eq("tags_downcase")
      end

      it "should use the raw value if attributes_to_replace does not have a hash for this attribute" do
        instance = described_class.new(:names.all, 'Some Value|Some Other Value|Another value', attributes_to_replace)
        instance.value.should eq({ "$all" => ['Some Value', 'Some Other Value', 'Another value'] })
      end

      it "should replace the raw value for the result of given proc in the :convert_value_to key" do
        instance = described_class.new(:names.all, 'Some Value|Some Other Value|Another value', attributes_to_replace_with_hash)
        instance.value.should eq({ "$all" => ['some value', 'some other value', 'another value'] })
      end

      it "should replace the raw value for the result of given proc in the :convert_value_to key, using other given params" do
        instance = described_class.new(:status, 'published', attributes_to_replace_with_hash, {:product_id => 1})
        instance.value.should eq('published_for_product')
      end
    end

  end
end
