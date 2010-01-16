# bacon spec/io/spec_stack-of-lines-like.rb

require 'bacon'
require 'hipe-core/io/stack-of-lines-like'
require 'ruby-debug'

readonly = File.join(File.dirname(__FILE__),'read-only')

include Hipe::Io

describe StackOfLinesLike do

  it "will throw on wierd arg type (sol0.5)" do
    e = lambda{StackOfLinesLike[Object]}.should.raise(Hipe::Exception)
    e.message.should.match(%r{must take an IO or a filename})
  end

  it "will throw if you give it a closed filehanld (sol0.75)" do
    fh = File.open(File.join(readonly,'stack-of-lines.txt'))
    fh.close
    e = lambda{StackOfLinesLike[fh]}.should.raise(Hipe::Exception)
    e.message.should.match(%r{must be an open filehandle})
  end

  it "will raise on string of no file (sol1)" do
    fn = File.join(readonly,"not-there.txt")
    lambda{StackOfLinesLike[fn]}.should.raise(Errno::ENOENT)
  end

  it "will create a file object from a string (sol2)" do
    fn = File.join(readonly,"stack-of-lines.txt")
    fh = StackOfLinesLike[fn]
    fh.should.be.kind_of(File)
    fh.should.respond_to(:peek)
    fh.should.respond_to(:pop)
  end

  it "will work on a file with three lines (sol3)" do
    stack = StackOfLinesLike[File.join(readonly,'stack-of-lines-trailing-newline.txt')]
    stack.peek.should.equal("one\n")
    stack.peek.should.equal("one\n")
    stack.pop.should.equal("one\n")
    stack.pop.should.equal("two\n")
    stack.pop.should.equal("three\n")
    stack.pop.should.equal(nil)
    stack.pop.should.equal(nil)
  end

  it "wil work with appropirate combinations of peeks and pops (sol4)" do
    stack = StackOfLinesLike[File.join(readonly,'stack-of-lines-trailing-newline.txt')]
    stack.pop.should.equal("one\n")
    stack.peek.should.equal("two\n")
    stack.pop.should.equal("two\n")
    stack.peek.should.equal("three\n")
    stack.peek.should.equal("three\n")
    stack.pop.should.equal("three\n")
    stack.peek.should.equal(nil)
    stack.peek.should.equal(nil)
  end

end
