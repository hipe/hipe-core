# bacon spec/spec_core.rb
require 'hipe-core'
require 'ruby-debug'

describe Hipe::Exception do
  it "can be constructed with no arguments (c1)" do
    e = Hipe::Exception.new
    e.should.be.kind_of? Hipe::Exception # looks like a pointless test but we've done some wicked things
    # with turning the 'new' class method into a factory before
  end

  it "can construct in the conventional manner (c2)" do
    e = Hipe::Exception.new("blah")
    e.message.should.equal "blah"
  end

  it "allows the appending of details (c2)" do
    e = Hipe::Exception.new("blah",:one=>'two',:three=>'four')
    e.message.should.equal "blah"
    e.details.keys.map{|x| x.to_s}.sort.should.equal(['one','three'])
  end

  it 'supports construction with its factory stub method ("[]") and is the same as new(c3)' do
    e1 = Hipe::Exception["blah",{:one=>'two',:three=>'four'}]
    e2 = Hipe::Exception.new("blah",:one=>'two',:three=>'four')
    e1.message.should.equal(e2.message)
    e1.details.should.equal(e2.details)
  end

  it "if you try anythign wierd, it still puts everything in details (c4)" do
    e = Hipe::Exception[{:blah => 'one', :blah2 => 'two'}]
    e.details.values.sort.should.equal(['one','two'])
    o = Object.new
    e = Hipe::Exception[o, IO, 'blah']
    e.details[Array].should.equal [o, IO, 'blah']
  end
end
