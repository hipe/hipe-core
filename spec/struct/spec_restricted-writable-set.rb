# bacon spec/struct/spec_restricted-writable-set.rb
require 'hipe-core/struct/restricted-writable-set'
require 'bacon'
require 'hipe-core/test/bacon-extensions'
require 'ruby-debug'

describe Hipe::RestrictedWritableSet do

  it "should inspect (rws1)" do
    @rws = Hipe::RestrictedWritableSet.new([:alpha,:beta, :gamma])
    have = @rws.inspect
    have.should.equal "#<Hipe::RestrictedWritableSet: {} @whitelist: {:alpha, :beta, :gamma}>"
  end

  it "should add (rws2)" do
    @rws.add(:alpha)
    @rws.include?(:alpha).should.equal true
  end

  it "should merge an array (rws3)" do
    @rws.merge([:beta,:gamma])
    @rws.subset?([:alpha,:beta,:gamma].to_set).should.equal true
  end

  it "should barf on bad add (rws4)" do
    @rws = Hipe::RestrictedWritableSet.new([:alpha,:beta, :gamma])
    e = lambda{@rws.add(:delta)}.should.raise ArgumentError
    @rws.include?(:delta).should.equal false
    e.message.scan(%r{(?:alpha|:beta|:gamma|:delta)}).size.should.equal 4
  end

  it "should barf on bad merge (rws4)" do
    e = lambda{@rws.merge([:zeta,:theta])}.should.raise ArgumentError
    e.message.scan(%r{(?:alpha|:beta|:gamma|:zeta|:theta)}).size.should.equal 5
    [:zeta,:theta].to_set.subset?(@rws).should.equal false
  end
end
