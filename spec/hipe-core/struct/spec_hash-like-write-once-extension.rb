# bacon spec/struct/spec_hash-like-write-once-extension.rb
require 'hipe-core'
require 'hipe-core/struct/hash-like-write-once-extension'
require 'ruby-debug'
require 'orderedhash'
require 'hipe-core/test/bacon-extensions'

class XyzzyException < Exception
end

describe Hipe::HashLikeWriteOnceExtension do
  it "on a plain old hash fetch and store still work (hl1)" do
    1.should.equal 1
    h = Hipe::HashLikeWriteOnceExtension[Hash.new]
    h.store('alpha','beta')
    h.fetch('alpha').should.equal('beta')
  end

  it "on a plain old hash fetch and store still work with []= and [] (hl2)" do
    1.should.equal 1
    @h = Hipe::HashLikeWriteOnceExtension[Hash.new]
    @h['alpha'] = 'beta'
    @h['alpha'].should.equal('beta')
  end

  it "respects write_once!  before the fact without a block, and maintain the orig. value (hl3)" do
    @h.write_once! :gamma
    @h[:gamma] = 'gamma'
    @h[:gamma].should.equal 'gamma'
    e = lambda{@h[:gamma]='beta'}.should.raise(TypeError)
    @h[:gamma].should.equal 'gamma'
    e.message.should.match %r{can't overwrite}
  end

  it "respects write_once! after the fact without a block, and maintain the orig. value(hl4)" do
    @h =  Hipe::HashLikeWriteOnceExtension[Hash.new]
    @h[:gamma] = 'gammaz'
    @h.write_once! :gamma
    @h[:gamma].should.equal 'gammaz'
    e = lambda{@h[:gamma]='beta'}.should.raise(TypeError)
    @h[:gamma].should.equal 'gammaz'
    e.message.should.match %r{can't overwrite}
  end

  it "should support custom clobber routines that throw, and maintain orig value (hl5)" do
    @h =  Hipe::HashLikeWriteOnceExtension[Hash.new]
    @h.write_once!(:gamma){|key,value| raise XyzzyException.new(%{blah blah #{key}})}
    @h[:gamma] = 'gammaz'
    @h[:gamma].should.equal 'gammaz'
    e = lambda{@h[:gamma]='beta'}.should.raise(XyzzyException)
    e.message.should.match %r{blah blah gamma}
    @h[:gamma].should.equal 'gammaz'
  end

  it "should support custom clobber routines that don't throw, and maintain orig value (hl6)" do
    @h =  Hipe::HashLikeWriteOnceExtension[Hash.new]
    val = 'ok'
    @h.write_once!(:gamma){|key,value|  val = 'not ok'}
    @h[:gamma] = 'gammaz'
    @h[:gamma].should.equal 'gammaz'
    @h[:gamma]='beta'  # should do nothing
    @h[:gamma].should.equal 'gammaz'
    val.should.equal 'not ok'
  end

  it "should work with an ordered def has (h17)" do
    @h =  Hipe::HashLikeWriteOnceExtension[OrderedHash.new]
    @h.write_once!(:gamma){|key,value| raise XyzzyException.new(%{blah blah #{key}})}
    @h[:gamma] = 'gammaz'
    @h[:gamma].should.equal 'gammaz'
    ['one','two','three'].each{|k| @h[k] = k }
    e = lambda{@h[:gamma]='beta'}.should.raise(XyzzyException)
    e.message.should.match %r{blah blah gamma}
    ['four','five','siz'].each{|k| @h[k] = k }
    @h[:gamma].should.equal 'gammaz'
    target = [:gamma,'one','two','three','four','five','siz']
    keys =  @h.keys
    keys.should.equal target
  end

end
