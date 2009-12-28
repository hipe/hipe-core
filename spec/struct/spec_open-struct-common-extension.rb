# bacon spec/struct/spec_open-struct-common-extension.rb
require 'bacon'
require 'hipe-core/struct/open-struct-extended'
require 'ruby-debug'

describe Hipe::OpenStructExtended do
  gauntlet = {
    :each     => lambda{|x| x.each{|x| x[1]<<'!'}},
    :keys     => lambda{|x| x.keys.map{|x| x.to_s}.sort },
    :has_key? => lambda{|x,y| x.has_key?(y) },
    :delete   => lambda{|x,y| x.delete(y) }
  }

  it "should keys like hash (ose1)" do
    @hash = {:alpha=>'ALPHA', 'beta'=>'BETA', :gamm_ma => 'GAMMA' }
    @ose  = Hipe::OpenStructExtended.new(@hash)
    gauntlet[:keys].call(@hash).should.equal gauntlet[:keys].call(@ose)
  end

  it "should has_key? like hash (ose2)" do
    gauntlet[:has_key?].call(@hash,:no).should.equal gauntlet[:has_key?].call(@ose,:no)
    gauntlet[:has_key?].call(@hash,:alpha).should.equal gauntlet[:has_key?].call(@ose,:alpha)
    @ose.has_key?(:no).should.equal false
    @ose.has_key?(:alpha).should.equal true
  end

  it "should confuse you (ose3)" do
    @ose.table.object_id.should.not.equal @hash.object_id
    gauntlet[:each].call(@ose)
    gauntlet[:each].call(@hash)
    (@ose.values.sort.to_s + @hash.values.sort.to_s).should.equal "ALPHA!!BETA!!GAMMA!!ALPHA!!BETA!!GAMMA!!"
  end

  it "should confuse you still (ose4)" do
    @hash = {:alpha=>'ALPHA'}
    @ose  = Hipe::OpenStructExtended.new(@hash.dup)
    @ose.table[:alpha] << 'blah'
    @hash[:alpha].should.equal "ALPHAblah"
  end

  it "should delete like hash (ose5)" do
    gauntlet[:delete].call(@ose,:alpha).should.equal gauntlet[:delete].call(@hash,:alpha)
    gauntlet[:delete].call(@ose,:not_there).should.equal gauntlet[:delete].call(@hash,:not_there)
    @ose.to_hash.should.equal @ose.symbolize_keys_of(@hash)
  end

  it "should merge els stricto el recurso (ose6)" do
    ose1 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :c => 'd',
         :g => { :h => 'i', :l => [:m,:n,:o], :s => 123 }
       }
    )
    ose2 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :e => 'f',
         :g => { :h => 'i', :j => 'k', :l => [:p, :q, :r] }
       }
    )
    ose1.deep_merge_strict!(ose2)
    ose1.to_hash.should.equal({
      :a => 'bb',
      :c => 'd',
      :e => 'f',
      :g => { :h => 'ii', :j => 'k', :l => [:m,:n,:o,:p,:q,:r], :s => 123 }
    })
  end


  it "should complaino 1 (ose7)" do
    ose1 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :c => 'd',
         :g => { :h => 'i', :j => 0, :l => [:m,:n,:o], :s => 123 }
       }
    )
    ose2 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :e => 'f',
         :g => { :h => 'i', :j => 'k', :l => [:p, :q, :r] }
       }
    )
    e = lambda{
      ose1.deep_merge_strict!(ose2)
    }.should.raise(ArgumentError)
    e.message.should.match %r{won't compare elements of different classes: Fixnum and String at ":g/:j"}
  end

  it "should complaino 2 (ose8)" do
    ose1 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :c => 'd',
         :g => { :h => 'i', :j => :k, :l => [:m,:n,:o], :s => 123 }
       }
    )
    ose2 = Hipe::OpenStructExtended.new(
       { :a => 'b',
         :e => 'f',
         :g => { :h => 'i', :j => :z, :l => [:p, :q, :r] }
       }
    )
    e = lambda{
      ose1.deep_merge_strict!(ose2)
    }.should.raise(ArgumentError)
    e.message.should.match %r{collision of elements that were not equal: :k and :z at ":g/:j"}
  end

end

