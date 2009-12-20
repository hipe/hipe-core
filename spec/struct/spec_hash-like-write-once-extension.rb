# bacon spec/struct/spec_hash-like-write-once-extension.rb
require 'hipe-core'
require 'hipe-core/struct/hash-like-write-once-extension'
require 'ruby-debug'


describe Hipe::HashLikeWriteOnceExtension do
  it "on a plain old hash fetch and store still work (hl1)" do
    1.should.equal 1
    h = Hipe::HashLikeWriteOnceExtension[Hash.new]
    h.store('alpha','beta')
    h.fetch('alpha').should.equal('beta')
  end
end