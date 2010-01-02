# bacon spec/loquacious/spec_base.rb
require 'bacon'
require 'hipe-core/loquacious/all'
require 'ruby-debug'
require 'hipe-core/test/bacon-extensions'

module Hipe::Loquacious

  module DuckLike; end

  class ADuck
    include DuckLike
    def to_str
      'duck as a string'
    end
  end

  class NotADuck; end

  class SomeClass
    include Hipe::Loquacious::AttrAccessor
    block_accessor    :filter
    boolean_accessor  :hidden
    boolean_accessor  :hidden2, :nil => true
    enum_accessor     :size, [:small,:medium,:large]
    integer_accessor  :number
    integer_accessor  :age, :min => 0, :max => 120
    integer_accessor  :turtle_age, :min => 0
    kind_of_accessor  :duck, DuckLike
    string_accessor   :name
    string_accessor   :name2, :use => :to_str
    string_accessor   :email, :regexp =>/@/
    symbol_accessor   :method
  end

  describe Hipe::Loquacious, SomeClass, 'every basic setter' do
    before do
      @x = SomeClass.new
    end

    it "bool ok (loq-bo-1)" do
      (@x.hidden.equal? nil).should.equal true
      @x.hidden = true
      @x.hidden.should.equal true
      (@x.hidden? == true).should.equal true
    end

    it "bool raise type (loq-bo-2)" do
      e = lambda{  @x.hidden = 'blah' }.should.raise(ArgumentError)
      e.message.should.match %r{blah.* is a invalid value for .?hidden.?.* (?:two|2|) ?valid values.*true and false}
    end

    it "bool raise nil (loq-bo-3)" do
      e = lambda{  @x.hidden = nil }.should.raise(ArgumentError)
      e.message.should.match %r{nil is a invalid value for hidden. There are two valid values: true and false}i
    end

    it "bool nil ok (loq-bo-3)" do
      lambda{  @x.hidden2 = nil }.should.not.raise
      @x.hidden2.should.equal nil
    end

    it "blocks all (loq-blo-1)" do
      @x.filter.should.equal nil
      @x.filter{|x| 'xyz'}
      @x.filter.should.be.kind_of Proc
      p1 = @x.filter
      p1.should.be.kind_of Proc
      @x.filter{|x| 'xyz'}
      @x.filter.should.be.kind_of Proc
      p2 = @x.filter
      (p2.eql? p1).should.equal false
    end

    it "enums ok (loq-en-1)" do
      (@x.size.equal? nil).should.equal true
      @x.size = :medium
      @x.size.should.equal :medium
    end

    it "enums raise (loq-en-2)" do
      e = lambda{ @x.size = :x_large }.should.raise(ArgumentError)
      e.message.should.match %r{x.large.*small.*medium.*large}i
    end

    it "int no range (loq-int-0)" do
      @x.number.should.equal nil
      @x.number = 1
      @x.number.should.equal 1
    end

    it "int min range raise (loq-int-1)" do
      @x.turtle_age.should.equal nil
      e = lambda{@x.turtle_age = -1}.should.raise(ArgumentError)
      e.message.should.match %r{-1.*can't be below 0}
      @x.turtle_age.should.equal nil
    end

    it "int min range only raise ok (loq-int-2)" do
      e = lambda{@x.age = -1}.should.raise ArgumentError
      @x.age.should.equal nil
      e = lambda{@x.age = 121}.should.raise ArgumentError
      e.message.should.match %r{can't be above 120}
      e.message.should.match %r{121}
    end

    it "kind of ok (loq-ko-1)" do
      (@x.duck.equal? nil).should.equal true
      a_duck = ADuck.new
      @x.duck = a_duck
      (@x.duck.equal?(a_duck)).should.equal true
    end

    it "kind of raise (loq-ko-2)" do
      e = lambda{ @x.duck = NotADuck.new }.should.raise(ArgumentError)
      e.message.should.match %r{DuckLike}
      e.message.should.match %r{NotADuck}
    end

    it "refelction -- setter getter equality -- we have learned that hash() should return Fixnum (loq-ref-1)" do
      args1 = {:nil => true}
      args2 = {:nil => true}
      name1 = :jebbediah
      name2 = :jebbediah
      block1 = lambda{|x| 'yz'}
      block2 = block1 # you can't have it all
      sg1 = SymbolAttrAccessor.new name1, args1, &block1
      sg2 = SymbolAttrAccessor.new name2, args2, &block2
      hash = {}
      hash[sg1] = true
      hash[sg2] = true
      hash.size.should.equal 1
    end


    it "string ok (loq-str-1)" do
      @x.name = "jo"
      @x.name.should.equal "jo"
    end

    it "string raise (loq-str-2)" do
      e = lambda{ @x.name = :jo }.should.raise ArgumentError
      @x.name.should.equal nil
      e.message.should.match %r{needed name to be String, was :jo}
    end

    it "string coercision success (loq-str-3)" do
      @x.name2.should.equal nil
      @x.name2 = ADuck.new
      @x.name2.should.equal 'duck as a string'
    end

    it "string coercision unavailable (loq-str-4)" do
      @x.name2.should.equal nil
      e = lambda{ @x.name2 = 123 }.should.raise ArgumentError
      e.message.should.match %r{needed name2 to be String, was 123}i
      @x.name2.should.equal nil
    end

    it "string ok regexp (loq-str-5)" do
      @x.email = 'a@b.c'
      @x.email.should.equal 'a@b.c'
    end

    it "string raise regexp (loq-str-6)" do
      e = lambda{ @x.email = 'no'}.should.raise ArgumentError
      e.message.should.match %r{"no" did not match the expected pattern}
      @x.email.should.equal nil
    end


    it "symbol ok (loq-sym-1)" do
      @x.method = :jo
      @x.method.should.equal :jo
    end

    it "symbol raise (loq-sym-2)" do
      e = lambda{ @x.method = "jo" }.should.raise ArgumentError
      @x.method.should.equal nil
      e.message.should.match %r{needed method to be Symbol, was "jo"}
    end
  end

  class Subset
    include Hipe::Loquacious::AttrAccessor
    integer_accessor :height, :min => 0, :max => 10
    symbol_accessor :name
  end

  class Superset
    include Hipe::Loquacious::AttrAccessor
    integer_accessor :height, :min => 0, :max => 10
    symbol_accessor :name
    enum_accessor :things, [:grapes, :oranges, :pears]
  end

  describe Subset, "Superset with regards to inheiritance" do
    it "interfaces can be subsets and supersets of each other (loq-subset-1)" do
      Subset.accessors.to_set.subset?( Superset.accessors.to_set ).should.equal true
      Superset.accessors.to_set.subset?( Subset.accessors.to_set ).should.equal false
    end
  end

  class Parent
    include Hipe::Loquacious::AttrAccessor
    symbol_accessor :name
  end

  class Child < Parent
    symbol_accessor :favorite_color
  end

  describe Parent, "and Child inheritance!" do
    it "with inheiritance the child class should have its own copy of the set (loq-inheir-1)" do
      Parent.accessors.to_set.subset?(Child.accessors.to_set).should.equal true
      Child.accessors.to_set.subset?(Parent.accessors.to_set).should.equal false
    end
  end

  class CanHavePlurals
    include Hipe::Loquacious::AttrAccessor
    string_accessors :alpha, :beta, :gamma
  end

  describe CanHavePlurals do
    it "should work" do
      CanHavePlurals.accessors.size.should.equal 3
      o = CanHavePlurals.new
      o.alpha = 'beta'
      o.beta = 'gamma'
      o.gamma = 'delta'
      (o.alpha << o.beta << o.gamma).should.equal "betagammadelta"
    end
  end

end
