# bacon spec/infrastructure/spec_strict-setter-getter.rb
require 'bacon'
require 'hipe-core/infrastructure/strict-setter-getter'
require 'ruby-debug'

module Hipe::StrictSetterGetter

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

  class ClassWithInterfaceSubset
    extend Hipe::StrictSetterGetter
    symbol_setter_getter :cartoon_character, :enum => [:beavis, :butthead]
    kind_of_each_setter_getter :duck, DuckLike
  end

  ShouldBeTypeError = begin
    class OtherClass
      extend Hipe::StrictSetterGetter
      kind_of_each_setter_getter :duck, ADuck.new
    end
  rescue TypeError => e; e; end

  describe self do
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
      e.message.should.match %r{Expecting either [a-z:]*DuckLike or Fixnum\.  Had Float\.}i
    end

    it "refelction -- setter getter equality -- we have learned that hash() should return Fixnum (ssg7)" do
      args1 = {:jeb => 'bush'}
      args2 = {:jeb => 'bush'}
      name1 = 'jebbediah'
      name2 = 'jebbediah'
      block1 = lambda{|x| 'yz'}
      block2 = block1 # you can't have it all
      sg1 = SymbolSetterGetter.new name1, *args1, &block1
      sg2 = SymbolSetterGetter.new name2, *args2, &block2
      hash = {}
      hash[sg1] = true
      hash[sg2] = true
      hash.size.should.equal 1
    end

    it "reflection -- awesome and maybe useless (ssg8)" do
      ClassWithInterfaceSubset.strict_setter_getters.subset?(SomeClass.strict_setter_getters).should.equal true
    end
  end


  class Parent
    extend Hipe::StrictSetterGetter
    symbol_setter_getter :name
  end

  class Child < Parent
    symbol_setter_getter :favorite_color
  end

  describe self, "with regards to inheiritance" do
    it "things got a little hairy when we got to inheiritance but no big deal, right? (ssg9)" do
      (Parent.strict_setter_getters.subset? Child.strict_setter_getters).should.equal true
      (Child.strict_setter_getters.subset? Parent.strict_setter_getters).should.equal false
    end
  end

end
