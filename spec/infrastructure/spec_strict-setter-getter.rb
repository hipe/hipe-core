# bacon spec/infrastructure/spec_strict-setter-getter.rb
require 'bacon'
require 'hipe-core/infrastructure/strict-setter-getter'
require 'ruby-debug'

class SomeClass
  extend Hipe::StrictSetterGetter
  symbol_setter_getter :cartoon_character, :enum => [:beavis, :butthead]
end

describe Hipe::StrictSetterGetter do
  it "should do symbols (ssg1)" do
    @x = SomeClass.new
    (@x.cartoon_character.equal? nil).should.equal true
    @x.cartoon_character = :beavis
    @x.cartoon_character.should.equal :beavis
  end

  it "should throw correctly (ssg2)" do
    e = lambda{ @x.cartoon_character = :daffy }.should.raise(ArgumentError)
    e.message.should.match %r{Expecting either :beavis or :butthead.  Had :daffy}i
  end

end
