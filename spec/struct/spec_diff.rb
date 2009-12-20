# bacon spec/struct/spec_diff.rb
require 'bacon'
require 'hipe-core/struct/diff'
require File.expand_path(File.dirname(__FILE__)+'/../bacon-test-strap')
require 'ruby-debug'

out = $stdout
def get_fixture(name)
  fn = File.dirname(__FILE__)+%{/structdiff/fixtures/#{name}.marshal}
  ret = Marshal.load(File.read(fn))
  ret
end

describe Hipe::StructDiff do
  before do
    @left = {
      :alpha  => 1,
      'delta' => 3,
      :beta   => 2,
      'gamma' => 4,
    }
    @right = {
      :beta   => 2,
      'delta' => 3,
      'gamma' => 4,
      :alpha  => 1,
    }
  end

  it "simple sorting of uninvolved nodes (s0)" do
    left = {}
    left['i disappear'] = { 'a'=>'','z'=>'','m'=>'','q'=>'',:b=>''}
    right = {}
    d = Hipe::StructDiff.diff(left,right,:sort=>1)
    d.summarize.include?(%[removed: {"i disappear"=>{"a"=>"", :b=>"", "m"=>"", "q"=>"", "z"=>""}}]).should == true
  end

  it "should work with ordered hashing (s1)" do
    d = Hipe::StructDiff.diff(@left,@right,:sort=>1)
    d.summarize.should.match(/none/)
  end

  it "should provide a somewhat complex sorted diff (s2)" do
    @left['epsilon']  = 5
    @left[:zeta]      = 6
    @left['eta']      = 7
    @left['i change'] = { :orange=>'citrus', :apple=>'ungulate', }
    @left['i disappear'] = { 'a'=>'','z'=>'','m'=>'','q'=>'',:b=>''}
    @right[:theta]    = 5
    @right['iota']    = 6
    @right[:kappa]    = 7
    @right['i change'] = { :orange=>'ditrus', :apple=>'ungulate', :banana=>'phone'}
    @right['i am added'] = { 'z'=>'',:x=>'','y'=>'',:w=>'' }
    d = Hipe::StructDiff.diff(@left,@right,:sort=>1)
    have = d.summarize
    target = <<-BLAH.gsub(/^    /,'')

    removed: {"epsilon"=>5, "eta"=>7, "i disappear"=>{"a"=>"", :b=>"", "m"=>"", "q"=>"", "z"=>""}, :zeta=>6}
    added:    {"i am added"=>{:w=>"", :x=>"", "y"=>"", "z"=>""}, "iota"=>6, :kappa=>7, :theta=>5}
      - i change:
        added:    {:banana=>"phone"}
          - orange:
            removed: "citrus"
            added:    "ditrus"
    BLAH
    have.should == target
  end

  it "should work (s3)" do

    left = {
      :fruit=>'apple',
      :lunch=>'beavis',
      :dinner=>'potato',
      :salad=>{:dressing=>'french',:eggs=>'scrambled'},
      :difftypes => {:what=>'about_this'},
    }
    right = {
      :fruit=>'apple',
      :breakfast=>'pear',
      :brunch=>'tofu',
      :dinner=>'potato',
      :salad=>{:dressing=>'french',:bacon=>'ranch',:eggs=>'on toast'},
      :difftypes => nil,
      :blah => {:blah=>'1',:blahh=>'2'}
    }
    diff = Hipe::StructDiff.diff(left,right,:sort=>1)
    # target = get_fixture('diff1')
    have = diff.summarize
    want = <<-TARGET.gsub(/^    /,'')

    removed: {:lunch=>"beavis"}
    added:    {:blah=>{:blah=>"1", :blahh=>"2"}, :breakfast=>"pear", :brunch=>"tofu"}
      - difftypes:
        removed: {:what=>"about_this"}
      - salad:
        added:    {:bacon=>"ranch"}
          - eggs:
            removed: "scrambled"
            added:    "on toast"
    TARGET

    have.should == want
  end

  it "should summarize" do
    left = {
      :firstname=>'jake'
    }
    right = {
      :firstname=>'sara'
    }
    diff = Hipe::StructDiff.diff(left,right)
    diff.filter_for(:firstname,:left){ "WANKERS" }
    result = diff.summarize
    target = <<-HERE.gsub(/^    /,'')

      - firstname:
        removed: WANKERS
        added:    "sara"
    HERE
    result.should == target
  end
end
