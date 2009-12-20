# bacon spec/logic/spec_rules-lite.rb
require 'bacon'
require File.expand_path(File.dirname(__FILE__)+'/../bacon-test-strap')
require 'hipe-core/logic/rules-lite'
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
    result = @r.assert(:t => true)
    result.should.equal 'true'
  end

  it "fails when assert is not hash like (rl2)" do
    e = lambda{ @r.assert(NilClass) }.should.raise(Hipe::Exception)
    e.message.should.match %r{must take a hash-like}
  end

  it "fails when duping names of rules (rl3)" do
    e = lambda{  Hipe::RulesLite.new{ rule('a'){}; rule('a'){} } }.should.raise(Hipe::Exception)
    e.message.should.match %r{cannot redefine}
  end

  it "returns nil on no match (rl4)" do
    rs = @r.assert(:t => false)
    rs.should.equal nil
  end

  it "raises NameError on bad name in condition (rl5)" do
    lambda{ rs = @r.assert(:u => true) }.should.raise(NameError)
  end

end
