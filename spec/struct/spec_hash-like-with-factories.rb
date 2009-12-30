# bacon spec/struct/spec_hash-like-with-factories.rb
require 'hipe-core/struct/hash-like-with-factories'
require 'bacon'
require 'ruby-debug'

module Hipe

  class ToStringCaster; def cast(thing); thing.to_s end end
  class ToIntegerCaster; def cast(thing); thing.to_i end end

  class TestHlwf < HashLikeWithFactories
    register_factory :string, ToStringCaster
  end

  describe HashLikeWithFactories do

    before do
      @hash = TestHlwf.new
    end

    it "should say that it has keys when it really doesn't (strct-hlwf-1)" do
      @hash.keys.map{|x| x.to_s}.sort.should.equal ['string']
    end

    it "should also allow normal addition of arbitrary objects (strct-hlwf-2)" do
      @hash[:integer] = ToIntegerCaster.new
      @hash.keys.map{|x| x.to_s}.sort.should.equal ['integer','string']
    end

    it "should create the objects the first time retrieve it a second time (strct-hlwf-3)" do
      it = @hash[:string]
      it.cast(:a_symbol).should.equal "a_symbol"
      @hash[:string].equal?(it).should.equal true
    end
  end
end
