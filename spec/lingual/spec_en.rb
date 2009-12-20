# bacon spec/lingual/spec_en.rb
require 'hipe-core/test/bacon-extensions'
require 'hipe-core/lingual/en'
require 'ruby-debug'

describe Hipe::Lingual::En do
  it "won't just build a sentence out of strings (en1)" do
    e = lambda{ Hipe::Lingual.en{ sp('a') } }.should.raise(Hipe::Exception)
    e.message.should.equal %{Invalid element to build a sentence phrase "a"}
  end

  it "dynamically build sentences for listing, taking whether it should say the count into account (en2)" do
    sp = Hipe::Lingual.en{
      sp(
        np('love',
          pp('in','my','life'),
          ["sex","drugs","world of warcraft"]
        )
      )
    }
    sp.outs << notice_stream
    "there are three loves in my life: sex, drugs and world of warcraft".should.equal sp.say

    sp.np.say_count = false
    "loves in my life are: sex, drugs and world of warcraft".should.equal sp.say

    sp.np.artp = Hipe::Lingual::En.artp(:def)
    "the loves in my life are: sex, drugs and world of warcraft".should.equal sp.say

    sp.np.artp = nil
    sp.np.list = ['jesus christ']
    sp.np.say_count = true
    "there is one love in my life: jesus christ".should.equal sp.say
    sp.np.say_count = false
    "there is one love in my life: jesus christ".should.equal sp.say

    sp.np.artp = Hipe::Lingual::En.artp(:def)
    "there is the one love in my life: jesus christ".should.equal sp.say

    sp.np.list = []
    "there are no loves in my life".should.equal sp.say

    sp = Hipe::Lingual.en{
      sp(
        np('love',pp('in my life'), ['billy','sara','joe'],:say_count => false)
      )
    }
    sp.outs << notice_stream
    "loves in my life are: billy, sara and joe".should.equal sp.say
  end

  it "should express quantity naturally for lists of 0, 1 or 2 items (en3)" do
    sp = Hipe::Lingual.en{
      sp(
        np('user',
          pp('currently','online')
        )
      )
    }
    sp.outs << notice_stream
    
    sp.np.list = []
    sp.say.should.equal "there are no users currently online"

    sp.np.list = ['joe']
    sp.say.should.match( /there is(?: only)? one user currently online:? "?joe"?/ )

    sp.np.say_count = true
    sp.np.list = ['jim','sara']
    sp.say.should.match( /there are two users currently online:? jim and sara/ )
  end

  it "should work with different count setting (en4)" do
    sp = Hipe::Lingual.en{ sp(np(adjp('valid'),'option')) }
    sp.outs << notice_stream    
    sp.np.say_count = false
    sp.np.list = []
    sp.say.should.match %r{there are no valid options}

    sp.np.list = ['joe']
    sp.say.should.match %r{there is(?: only)? one valid option:? joe}

    sp.np.list = ['jim','sara']
    sp.say.should.match %r{valid options are:? jim and sara}
  end

  it "should work with definite article and a count from zero to infinity (en5)" do
    np = Hipe::Lingual.en{ np(:the,'amigo',4)}
    np.outs << notice_stream
    "the 4 amigos".should.equal np.say
    np.size = 3
    "the three amigos".should.equal np.say
    np.size = 2
    "the two amigos".should.equal np.say  
    np.size = 1
    "the one amigo".should.equal np.say
    np.size = 0
    "no amigos".should.equal np.say
  end

  it "should use some kind of defaults when there is no article and no count (en6)" do
    sp = Hipe::Lingual.en{ np('amigo') }    
    sp.outs << notice_stream    
    "amigo".should.equal sp.say
  end

  it "should express quantity in a casual way when it is known and the article is indefinite (en7)" do
    Hipe::Lingual::En.outs << notice_stream    
    "a lot of amigos"    .should.equal     Hipe::Lingual.en{ np(:an,'amigo',6) }.say
    "several amigos"     .should.equal     Hipe::Lingual.en{ np(:an,'amigo',5) }.say
    "some amigos"        .should.equal     Hipe::Lingual.en{ np(:an,'amigo',4) }.say
    "a few amigos"       .should.equal     Hipe::Lingual.en{ np(:an,'amigo',3) }.say
    "a couple of amigos" .should.equal     Hipe::Lingual.en{ np(:an,'amigo',2) }.say
    "an amigo"           .should.equal     Hipe::Lingual.en{ np(:an,'amigo',1) }.say
    "no amigos"          .should.equal     Hipe::Lingual.en{ np(:an,'amigo',0) }.say
  end
end
