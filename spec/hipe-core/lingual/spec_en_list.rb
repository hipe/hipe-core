# bacon spec/spec_en_list.rb
require 'hipe-core/lingual/en'
require 'bacon'
require 'ruby-debug'

describe Hipe::Lingual::List do
  it "should work on empty (l1)" do
    Hipe::Lingual::List[[]].either.should == 'nothing'
    Hipe::Lingual::List[[]].or.should     == 'nothing'
    Hipe::Lingual::List[[]].and.should    == 'nothing'
  end

  it "should work on one (l2)" do
    Hipe::Lingual::List[%w(beavis)].either.should  == 'beavis'
    Hipe::Lingual::List[%w(beavis)].or.should      == 'beavis'
    Hipe::Lingual::List[%w(beavis)].and.should     == 'beavis'
  end

  it "should work on three (l3)" do
    Hipe::Lingual::List[%w(beavis butthead)].either.should  == 'either beavis or butthead'
    Hipe::Lingual::List[%w(beavis butthead)].or.should      == 'beavis or butthead'
    Hipe::Lingual::List[%w(beavis butthead)].and.should     == 'beavis and butthead'
  end

  it "should work on four (l4)" do
    Hipe::Lingual::List[%w(beavis butthead DARIA)].either.should  == 'either beavis, butthead or DARIA'
    Hipe::Lingual::List[%w(beavis butthead DARIA)].or.should      == 'beavis, butthead or DARIA'
    Hipe::Lingual::List[%w(beavis butthead DARIA)].and.should     == 'beavis, butthead and DARIA'
  end

  it "quote land (l5)" do
    Hipe::Lingual::List[%w(beavis butthead DARIA toucan-sam)].either{|x|%{"#{x}"}}.should  ==
      'either "beavis", "butthead", "DARIA" or "toucan-sam"'
  end
end
