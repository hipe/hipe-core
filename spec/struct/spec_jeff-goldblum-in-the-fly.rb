# bacon spec/struct/spec_jeff-goldblum-in-the-fly.rb
require 'hipe-core'
require 'orderedhash'
require 'hipe-core/struct/open-struct-like'
require 'hipe-core/struct/open-struct-write-once-extension'
require 'bacon'
require 'hipe-core/test/bacon-extensions'
require 'ruby-debug'
include Hipe

describe OpenStructWriteOnceExtension, "getting crazy" do
  it "can we have an ordered hash that is open struct like? (wtf1)" do
    @wtf = OpenStructWriteOnceExtension[OpenStructLike[OrderedHash.new]]
    @wtf[:blah] = 'blah one'
    @wtf[:blah2] = 'blah two'
    @wtf[:blah3] = 'blah three'
    @wtf.keys.should.equal [:blah, :blah2, :blah3]
    @wtf[:blah4].should.equal nil
    @wtf.blah.should.equal "blah one"
    @wtf.blah2.should.equal "blah two"
    @wtf.blah3.should.equal "blah three"
    @wtf.blah4.should.equal nil
    @wtf.size.should.equal 3
  end

  it "can we have an ordered hash that is write once that is open stuct like? (wtf2)" do
    @wtf.write_once! :blah, :blah5         # :blah is alread written, :blah5 is not
    e = lambda{ @wtf.blah = 'blah again' }.should.raise(TypeError)
    e.message.should.match %r{can't write}
    @wtf.blah5 = 'blah five'
    e = lambda{ @wtf.blah5 = 'blah file' }.should.raise(TypeError)
    e.message.should.match %r{can't write}
  end
end
