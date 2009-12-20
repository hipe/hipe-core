# bacon spec/lingual/spec_ascii-typesetting.rb
require 'hipe-core/lingual/ascii-typesetting'
require 'bacon'
require 'ruby-debug'

include Hipe::AsciiTypesetting::Methods
include Hipe::AsciiTypesetting

describe Hipe::AsciiTypesetting do

  it "truncate should work (at1)" do
    truncate('123456',5).should.equal '12...'
    truncate('123456',6).should.equal '123456'
    truncate('123456',7).should.equal '123456'
  end

  it "will do basic wordwrap like in active support (at5)" do
    input  = 'wow that was really easy to make a cli for this'
    output = wordwrap(input,10)
    target =
    'wow that
    was really
    easy to
    make a cli
    for this'.gsub(/^    /,'')
    output.should.equal target
  end

  it "wrapping in the middle of the word (at6)" do
    input  = 'in themiddleoftheword'
    output = wordwrap(input,10)
    target =
    'in
    themiddleoftheword'.gsub(/^    /,'')
    output.should.equal target
  end

  it "recursive brackets (at7)" do
    list = ['alpha','beta','gamma']
    s = recursive_brackets list,'[',']'
    s.should.equal('alpha[beta[gamma]]')
  end

end

describe FormattableString, 'with wordwrap and indent' do
  it "wordwrap changes the stirng and returns the same(a8)" do
    @item = FormattableString['wow that was really easy to make a cli for this']
    output = @item.word_wrap!(10)
    target =
    'wow that
    was really
    easy to
    make a cli
    for this'.gsub(/^    /,'')
    output.should.equal target
    @item.should.equal target
  end

  it "should indent to a specific number of spaces when passed an int(a9)" do
    @item.indent!(4)
    @item.should.equal '    wow that
    was really
    easy to
    make a cli
    for this'
  end

end


describe FormattableString, ' when sentence wrapping' do
  before do
    @string = FormattableString["One two three.  Four five six."]
  end

  it "should sentence wrap when the boundary is in the middle of the first sentence (at2)" do
    first = @string.sentence_wrap_once!(6)
    first.should.equal 'One...'
    @string.should.equal 'two three.  Four five six.'
  end

  it "should sentence wrap when the boundary is after the second sentence (at3)" do
    first = @string.sentence_wrap_once!(100)
    first.should.equal 'One two three.'
    @string.should.equal 'Four five six.'
  end

  it "should sentence wrap the sentences when the boundary is in the middle of the second sentence (at4)" do
    first = @string.sentence_wrap_once!(20)
    first.should.equal 'One two three.'
    @string.should.equal 'Four five six.'
  end

  it "i don't understand why it does this or what it is testing (at5)" do
    s = FormattableString["012 456 89"]
    s.sentence_wrap_once!(6).should.equal '012...'
    s.should.equal '456 89'
  end

end
