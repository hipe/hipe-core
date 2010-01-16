# bacon spec/struct/spec_open-struct-write-once-extension.rb
require 'bacon'
require 'ruby-debug'
require 'ostruct'
require 'hipe-core'
require 'hipe-core/struct/open-struct-write-once-extension'

describe Hipe::OpenStructWriteOnceExtension do
  it "should raise appropriately when asserting write_once after the fact. (wo1)" do
    @o = OpenStruct.new(:a=>'A',:b=>'B',:c=>'C')
    Hipe::OpenStructWriteOnceExtension[@o]
    @o.write_once! 'a',:b
    @o.a.should.equal 'A'
    @o.b.should.equal 'B'
    lambda{ @o.a = 'Z' }.should.raise(TypeError)
    lambda{ @o.a = 'B' }.should.raise(TypeError)
  end

  it "should raise appropriately when asserting write once before the fact (wo2)" do
    @o = OpenStruct.new
    Hipe::OpenStructWriteOnceExtension[@o]
    @o.write_once! 'a', :b
    @o.a = 'ok'
    @o.a.should.equal 'ok'
    @o.b = 'hi'
    @o.b.should.equal 'hi'
    lambda{@o.a = 'hi'}.should.raise(TypeError)
    lambda{@o.b = 'hi'}.should.raise(TypeError)
  end
end

