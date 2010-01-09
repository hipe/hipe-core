# bacon spec/lingual/en/spec_sentence-compression.rb
require 'bacon'
require 'hipe-core/lingual/en/sentence-compression'
require 'ruby-debug'

module Hipe::Lingual::En

  describe SentenceCompression do

    it "should work (sc2)" do
      @c = SentenceCompression.new
      @c << "i hate seamonkeys by the shore"
      @c << "i really absolutely hate seamonkeys lots"
      @c.to_s.should.equal "i really absolutely hate seamonkeys by the shore and lots"
    end

    it "should work, order matters (sc1)" do
      @c = SentenceCompression.new
      @c << "i really absolutely hate seamonkeys lots"
      @c << "i hate seamonkeys by the shore"
      @c.to_s.should.equal "i really absolutely hate seamonkeys lots and by the shore"
    end

    it "should pop this this into it too (sc3)" do
      @c << "i loath seamonkeys"
      @c.to_s.should.equal "i really absolutely hate and loath seamonkeys lots and by the shore"
    end

    it "should do inner and-list (sc4)" do
      @c = SentenceCompression.new
      @c << "i like apples a lot"
      @c << "i like bananas a lot"
      @c << "i like pears a lot"
      @c.to_s.should.equal "i like apples, bananas and pears a lot"
    end

    it "should respect threshold (sc4)" do
      @c = SentenceCompression.new
      @c << 'nothing in common'
      @c << 'with this sentence'
      @c << 'or thiz phrase'
      @c.say.should.equal "nothing in common  with this sentence  or thiz phrase"
    end
  end
end
