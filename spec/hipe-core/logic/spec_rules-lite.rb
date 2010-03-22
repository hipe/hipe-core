# bacon spec/logic/spec_rules-lite.rb
require 'bacon'
require 'hipe-core/test/bacon-extensions'
require 'hipe-core/logic/rules-lite'
require 'ostruct'
require 'ruby-debug'

describe Hipe::RulesLite do

  it "should run a simple example (rl1)" do
    @r = Hipe::RulesLite.new do
      rule "true on true, false on false" do
        condition{ t == true }
        consequence{ 'true' }
      end
    end
    result = {}
    result = @r.assess(:t => true)
    result.should.equal 'true'
  end

  it "throws TypeError when assess is used against something not hash like(rl2)" do
    e = lambda{ @r.assess(NilClass) }.should.raise(TypeError)
    e.message.should.match %r{must take a hash-like}
  end

  it "fails when duping names of rules (rl3)" do
    e = lambda{  Hipe::RulesLite.new{ rule('a'){}; rule('a'){} } }.should.raise(
      Hipe::RulesLite::Fail
    )
    e.message.should.match %r{cannot redefine}
  end

  it "returns nil on no match (rl4)" do
    rs = @r.assess(:t => false)
    rs.should.equal nil
  end

  it "raises NameError on bad name in condition (rl5)" do
    lambda{ rs = @r.assess(:u => true) }.should.raise(NameError)
  end

  it "should allow rules to reevalutate (rl6)" do
    @r = Hipe::RulesLite.new do
      rule "false at first" do
        condition { you.age >= 21 }
        consequence { 'have a drink' }
      end
      rule "get fake id if you know the right guy" do
        condition { you.know == 'dave' }
        consequence{   you.age = 21;  reevaluate  }
      end
    end
    you = OpenStruct.new(:know=>'bill', :age=>20)
    @r.assess( :you => you ).should.equal nil
    you.know = 'dave'
    @r.assess( :you => you ).should.equal 'have a drink'
  end

  it "should prevent rules from entering infinute loop when reevalutationg (rl7)" do

    @r = Hipe::RulesLite.new do
      rule "false at first" do
        condition { you.age >= 21 }
        consequence { 'have a drink' }
      end
      rule "get your age set to 19 if you know dave" do
        condition { you.know == 'dave' }
        consequence{   you.age = 19;  reevaluate  }
      end
    end
    you = OpenStruct.new(:know=>'dave', :age=>20)
    @r.assess( :you => you ).should.equal nil
  end
end
