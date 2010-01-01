# bacon spec/loquacious/spec_kind-of.rb
require 'hipe-core/loquacious/kind-of'
include Hipe::Loquacious

module TestMod
end
class TestGoodClass
  include TestMod
end
class TestBadClass
end

describe KindOf do
  it "should work (loq-ko-1)" do
    validator = KindOf.new(TestMod)
    validator.excludes?(TestGoodClass.new).should.equal nil
    validator.excludes?(TestBadClass.new).should.match %r{TestMod}
    validator.excludes?(TestBadClass.new).should.match %r{TestBadClass}
  end

  it "should barf on bad construction (loq-ko-2)" do
    e = lambda{ KindOf.new(Object.new) }.should.raise(TypeError)
    e.message.should.match %r{Object}
    e.message.should.match %r{Module}
  end

end
