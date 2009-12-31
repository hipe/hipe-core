# bacon spec/struct/spec_restricted-writable-set.rb
require 'hipe-core/struct/restricted-writable-set'
require 'bacon'
require 'ruby-debug'

describe Hipe::RestrictedWritableSet do
  it "should write (rws1)" do
    @rws = Hipe::RestrictedWritableSet.new([:alpha,:beta])
    debugger
    'x'
  end
end