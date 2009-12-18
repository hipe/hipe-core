# bacon spec/io/spec_stack-of-lines.rb

require 'bacon'
require 'hipe-core/io/stack-of-lines-like'
require 'ruby-debug'

readonly = File.join(File.expand_path('../../../',__FILE__),'spec','io','read-only')

include Hipe::Io

describe "hipe-core/io/stack-of-lines-like" do
  it "should raise on string of no file (sol1)" do
    fn = File.join(readonly,"not-there.txt")
    lambda{StackOfLinesLike[fn]}.should.raise(Errno::ENOENT)
  end
  
  it "should create a file object from a string (sol2)" do
    fn = File.join(readonly,"stack-of-lines.txt")    
    fh = StackOfLinesLike[fn]
    fh.should.be.kind_of(File)
    fh.should.respond_to(:peek)
    fh.should.respond_to(:pop)  
  end
  
  it "should work on a file with three lines (sol3)" do
    stack = StackOfLinesLike[File.join(readonly,'stack-of-lines-trailing-newline.txt')]
    stack.peek.should.equal("one\n")
    stack.peek.should.equal("one\n")
    stack.pop.should.equal("one\n")    
    stack.pop.should.equal("two\n")
    stack.pop.should.equal("three\n")    
    stack.pop.should.equal(nil)
    stack.pop.should.equal(nil)
  end
  
  it "same thing slight variation (sol4)" do 
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
