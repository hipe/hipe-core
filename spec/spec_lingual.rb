# bacon test/lingual_test.rb
require 'hipe-core/lingual'
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


describe Hipe::Lingual::List do
  it "should work (l6)" do
    sp = Hipe::Lingual.en{ sp(np('user',pp('currently','online'))) }

    sp.np.list = []
    sp.say.should == "there are no users currently online."

    sp.np.list = ['joe']
    sp.say.should.match( /there is(?: only)? one user currently online:? "?joe"?/ )

    sp.np.say_count = true
    sp.np.list = ['jim','sara']
    sp.say.should.match( /there are two users currently online:? jim and sara/ )
  end

  it "should work with different count setting (l7)" do
    sp = Hipe::Lingual.en{ sp(np(adjp('valid'),'option')) }
    sp.np.say_count = false
    sp.np.list = []
    sp.say.should.match /there are no valid options/

    sp.np.list = ['joe']
    sp.say.should.match /there is(?: only)? one valid option:? joe/

    sp.np.list = ['jim','sara']
    sp.say.should.match /valid options are:? jim and sara/
  end
end
