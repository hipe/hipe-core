# bacon test/structdiff_test.rb
require 'hipe-core/structdiff'
require 'hipe-core/bufferstring'
require 'bacon'
require 'ruby-debug'

# out = Hipe::BufferString.new
out = $stdout
def get_fixture(name)
  fn = File.dirname(__FILE__)+%{/structdiff/fixtures/#{name}.marshal}
  ret = Marshal.load(File.read(fn))
  ret
end

describe Hipe::StructDiff do

  it "should work" do
    
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
    diff = Hipe::StructDiff.diff(left,right)
    target = get_fixture('diff1')
    puts diff.summarize
    # diff.should == target
    1.should == 1
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
    debugger
    result.should == target
  end
end
