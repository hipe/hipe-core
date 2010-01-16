# bacon spec/io/spec_golden-hammer.rb
require 'ruby-debug'
require 'hipe-core/io/golden-hammer'
require 'hipe-core/test/bacon-extensions'
require 'bacon'


describe Hipe::Io::GoldenHammer do
  skipit "should not flush! (gh1)" do
    io = StringIO.new
    gh = Hipe::Io::GoldenHammer.new
    gh.string.flush_to << io
    gh << "blah"
    gh.to_s.should.equal "blah"
    io.rewind
    io.read.should.equal ''
  end

  it "should flush! (gh2)" do
    io = StringIO.new
    gh = Hipe::Io::GoldenHammer.new
    gh.string.flush_to << io
    gh << "blah"
    gh.string.flush!
    gh.to_s.should.equal ""
    io.rewind
    io.read.should.equal "blah"
  end

  it "should compress sentences (gh3)" do
    out = Hipe::Io::GoldenHammer.new(:compress_messages => true)
    out2 = Hipe::Io::GoldenHammer.new(:message => "added beavis to the stack")
    out3 = Hipe::Io::GoldenHammer.new(:message => "added butthead to the stack")
    out4 = Hipe::Io::GoldenHammer.new(:message => "added daria to the stack")
    out.merge!(out2)
    out.merge!(out3)
    out.merge!(out4)
    out.to_s.should.equal "added beavis, butthead and daria to the stack"
  end

end
