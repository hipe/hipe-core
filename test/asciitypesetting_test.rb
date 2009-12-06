# bacon test/asciitypesetting_test.rb
require 'hipe-core/asciitypesetting'
require 'bacon'
require 'ruby-debug'

include Hipe::AsciiTypesetting
describe Hipe::AsciiTypesetting do 
  
  it "truncate should work" do
    truncate('123456',5).should == '12...'
    truncate('123456',6).should == '123456'
    truncate('123456',7).should == '123456'
  end


end


describe FormattableString do
  before do
    @string = FormattableString.new("One two three.  Four five six.")
  end
  
  it "should work" do 
    first = @string.sentence_wrap_once!(6)
    first.should == 'One...'
    @string.should == 'two three.  Four five six.'
  end  
  
  it "should work again" do 
    first = @string.sentence_wrap_once!(100)
    first.should == 'One two three.'
    @string.should == 'Four five six.'
  end  

  it "should work here also" do 
    first = @string.sentence_wrap_once!(20)
    first.should == 'One two three.'
    @string.should == 'Four five six.'
  end  
  
  it "should work (4)" do
    s = FormattableString.new "012 456 89" 
    s.sentence_wrap_once!(6).should == '012...'
    s.should == '456 89'
  end    
  
end