require 'spec_helper'

describe QueryStringInterface::SortingFilters do
  let :default_filters do
    [{:exhibited_at => :desc}, "title.desc"]
  end

  context "when no filters are given" do
    subject do
      described_class.new({}, default_filters)
    end

    it "should return the default filters, as an array of hashes, where each hash contains only one key (the field) with its value (the direction - asc or desc)" do
      subject.parse.should == [{:exhibited_at => :desc}, {:title => :desc}]
    end

    context "when no direction is given" do
      let :default_filters do
        ["title", "exhibited_at.desc", "hits"]
      end

      it "should use ascending" do
        subject.parse.should == [{:title => :asc}, {:exhibited_at => :desc}, {:hits => :asc}]
      end
    end

    describe "when a filter is an object that responds to key and operator methods" do
      let :default_filters do
        [:exhibited_at.desc, :title]
      end

      it "should return the default filters, properly parsed" do
        subject.parse.should == [{:exhibited_at => :desc}, {:title => :asc}]
      end

      context "and it has attributes to replace" do
        let :attributes_to_replace do
          {:title => :name, :exhibited_at => :some_date}
        end

        subject do
          described_class.new({}, default_filters, attributes_to_replace)
        end

        it "should properly replace the attributes" do
          subject.parse.should == [{:some_date => :desc}, {:name => :asc}]
        end
      end
    end

    context "when replacing attributes" do
      let :attributes_to_replace do
        {:title => :name}
      end

      subject do
        described_class.new({}, default_filters, attributes_to_replace)
      end

      it "should properly replace the attributes" do
        subject.parse.should == [{:exhibited_at => :desc}, {:name => :desc}]
      end
    end
  end

  context "when filters are given" do
    let :filters do
      {:order_by => "title.asc|exhibited_at.asc|hits.desc"}
    end

    subject do
      described_class.new(filters, default_filters)
    end

    it "should return the given filters, as an array of hashes, where each hash contains only one key (the field) with its value (the direction - asc or desc)" do
      subject.parse.should == [{:title => :asc}, {:exhibited_at => :asc}, {:hits => :desc}]
    end

    context "when no direction is given" do
      let :filters do
        {:order_by => "title|exhibited_at.desc|hits.asc"}
      end

      it "should use ascending" do
        subject.parse.should == [{:title => :asc}, {:exhibited_at => :desc}, {:hits => :asc}]
      end
    end

    describe "when a filter is an object that responds to key and operator methods" do
      let :filters do
        {:order_by => [:title.desc, :exhibited_at, :hits.asc]}
      end

      it "should return the given filters, properly parsed" do
        subject.parse.should == [{:title => :desc}, {:exhibited_at => :asc}, {:hits => :asc}]
      end

      context "and it has attributes to replace" do
        let :attributes_to_replace do
          {:title => :name, :exhibited_at => :some_date}
        end

        subject do
          described_class.new(filters, default_filters, attributes_to_replace)
        end

        it "should properly replace the attributes of the given filters" do
          subject.parse.should == [{:name => :desc}, {:some_date => :asc}, {:hits => :asc}]
        end
      end
    end

    context "when replacing attributes" do
      let :attributes_to_replace do
        {:title => :name, :hits => :counts }
      end

      subject do
        described_class.new(filters, default_filters, attributes_to_replace)
      end

      it "should properly replace the attributes" do
        subject.parse.should == [{:name => :asc}, {:exhibited_at => :asc}, {:counts => :desc}]
      end
    end
  end
end