# bacon spec/infrastructure/spec_strict-setter-getter.rb
require 'bacon'
require 'hipe-core/infrastructure/strict-setter-getter'
require 'ruby-debug'

module DuckLike
end
class ADuck
  include DuckLike
end
class NotADuck
end
class SomeClass
  extend Hipe::StrictSetterGetter
  symbol_setter_getter :cartoon_character, :enum => [:beavis, :butthead]
  kind_of_each_setter_getter :duck, DuckLike
  kind_of_setter_getter :blah, DuckLike, Fixnum
end

ShouldBeTypeError = begin
  class OtherClass
    extend Hipe::StrictSetterGetter
    kind_of_each_setter_getter :duck, ADuck.new
  end
rescue TypeError => e; e; end



describe Hipe::StrictSetterGetter do
  it "should do symbols (ssg1)" do
    @x = SomeClass.new
    (@x.cartoon_character.equal? nil).should.equal true
    @x.cartoon_character = :beavis
    @x.cartoon_character.should.equal :beavis
  end

  it "should raise correctly for symbols (ssg2)" do
    e = lambda{ @x.cartoon_character = :daffy }.should.raise(ArgumentError)
    e.message.should.match %r{Expecting either :beavis or :butthead.  Had :daffy}i
  end

  it "should do kind of (ssg3)" do
    @x = SomeClass.new
    (@x.duck.equal? nil).should.equal true
    a_duck = ADuck.new
    @x.duck = a_duck
    (@x.duck.equal?(a_duck)).should.equal true
  end

  it "should raise correctly for kind of (ssg4)" do
    e = lambda{ @x.duck = NotADuck.new }.should.raise(TypeError)
    e.message.should.match %r{DuckLike}
    e.message.should.match %r{NotADuck}
  end

  it "should raise correctly for kind of kind of (ssg5)" do
    ShouldBeTypeError.should.be.kind_of TypeError
    ShouldBeTypeError.message.should.match %r{Module}
    ShouldBeTypeError.message.should.match %r{ADuck}
  end

  it "new kind_of should work (ssg6)" do
    @x.blah.should.equal nil
    d = ADuck.new
    @x.blah = d
    (@x.blah.equal? d).should.equal true
    @x.blah = 7
    @x.blah.should.equal 7
    e = lambda{ @x.blah = 7.0 }.should.raise(TypeError)
    e.message.should.match %r{Expecting either DuckLike or Fixnum\.  Had Float\.}
  end

end
