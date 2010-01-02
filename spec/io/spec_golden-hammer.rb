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

end
