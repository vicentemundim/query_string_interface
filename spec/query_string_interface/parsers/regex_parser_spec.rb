require 'spec_helper'

describe QueryStringInterface::Parsers::RegexParser do
  it "should be able to parse a regex" do
    should be_parseable('/\d*(.*)-[a-zA-Z]/', nil)
  end

  it "should be able to parse a regex with modifiers" do
    should be_parseable('/\d*(.*)-[a-zA-Z]/i', nil)
  end

  it "should not be able to parse a text" do
    should_not be_parseable('Anything else', nil)
  end

  it "should not be able to parse an invalid regex" do
    should_not be_parseable('/dasdasds', nil)
  end

  it "should parse a regex" do
    subject.parse('/\d*(.*)-[a-zA-Z]/').should == /\d*(.*)-[a-zA-Z]/
  end

  it "should parse a regex with modifiers" do
    subject.parse('/\d*(.*)-[a-zA-Z]/i').should == /\d*(.*)-[a-zA-Z]/i
  end

  it "should not parse an invalid regex" do
    subject.parse('/\d*(.*)-[a-zA-Z]').should be_nil
  end

  it "should be able to parse regexp with '/' character" do
    ['/2012/20/i', "/2012/20/i", "/2012\/20/i"].each do |raw_regexp|
      regexp = subject.parse(raw_regexp)
      regexp.should eql(%r{2012/20}i), "Expected #{raw_regexp} to be parsed as #{regexp.inspect}"
      "2012/20".should match(regexp)
    end

    subject.parse("/2012/20/i").to_s.should eql((/2012\/20/i).to_s)
    "2012/20".should match(subject.parse('/2012\/20/i'))
  end
end