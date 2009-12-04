require 'rubygems'
require 'pp'

# Usage: diff = StructDiff::diff(hash1, hash2)
# 
#
#

module Hipe
  class StructDiff
    
    attr_accessor :name, :ignore_deletions #when reporting on changed keys
    
    def self.is_scalar obj
      case obj
        when String: true
        when Float: true
        when Fixnum: true
        when TrueClass: true
        when FalseClass: true
        when NilClass: true
        else false
      end
    end
    
    def initialize(diff)
      @diff = diff      
      unless is_scalar? # or is terminal
        @diff.each do |k,v|
          next unless @diff[k].respond_to? :each_key
          @diff[k].each_key do |kk|
            @childNames ||= {}
            @childNames[kk] ||= []
            @childNames[kk] << k
          end
        end
      end      
      @ignore_deletions = false
      @ign = {}
      @filter = {}
    end
    
    def middle_diff
      @diff[:diff]
    end
    
    def right
      @diff[:right]
    end
    
    def filter_for(field,hand,&proc)
      if (field.nil?)
        @filter[hand] = proc
      elsif (@childNames[field])
        @childNames[field].each do |hand2|
          @diff[hand2][field].filter_for(nil,hand,&proc)
        end
      end
    end    
    
    def left_value_for(field, &proc)
      filter_for(field,:left,&proc)
    end
    
    def right_value_for(field, &proc)
      filter_for(field,:right,&proc)
    end    
        
    def self.diff obj1, obj2 
      if obj1.class != obj2.class
        if (is_scalar obj1 and is_scalar obj2)
          is_scalar = 1
        end
        return new :left=>obj1, :right=>obj2, :is_scalar => is_scalar
      elsif is_scalar obj1
        if obj1 == obj2
          return new :no_diff=>true, :shared_value=>obj1, :is_scalar=>true
        else
          return new :left=>obj1, :right=>obj2, :is_scalar=>true
        end
      elsif (obj1.instance_of? Array)
        raise Exception.new("sorry not yet implemented -- don't know how to compare two arrays in ruby")
      elsif (obj1.instance_of? Hash)
        hashs = {:left => obj1,:right => obj2}
        ks = {
          :left  => (obj1.keys - obj2.keys),
          :right => (obj2.keys - obj1.keys)
        }
        ret = {}
        [:left,:right].each { |hand|
          if ks[hand].length > 0
            side = hashs[hand].clone.delete_if{|k,v| !ks[hand].include? k }
            ret[hand] = side if (side.size > 0)
          end 
        }
        same = (obj1.keys & obj2.keys)        
        all_shared_keys_have_same_values = true
        middle = {
          :diff => {},
          :same => {}
        }
        same.each do |k|
          subdiff = StructDiff.diff(obj1[k],obj2[k])
          if (subdiff.no_diff?)
            middle[:same][k] = subdiff
          else
            all_shared_keys_have_same_values = false            
            middle[:diff][k] = subdiff
          end
        end
        [:diff,:same].each { |k| ret[k] = middle[k] if middle[k].size > 0 }
        if (all_shared_keys_have_same_values && ks[:left].size == 0 && ks[:right].size == 0 )
          ret[:no_diff] = true
        end
        return self.new ret
      else #if chain   
        raise Exception.new(%{unhandled case: "#{obj1.class}" and "#{obj2.class}"});
      end
    end #def
    
    def ignore_deletions= value
      @ignore_deletions = value
      if (@diff[:diff]) 
        @diff[:diff].each do |k,v|
          v.ignore_deletions = value
        end
      end
    end
    
    def no_diff?
      return @diff[:is_scalar] ? @diff[:no_diff] : (diff_keys.size == 0)
    end
    
    def diff_keys(opts={})
      ks = [];
      ks += @diff[:left].keys if @diff[:left] && !@ignore_deletions
      ks += @diff[:right].keys if @diff[:right]
      if @diff[:diff] 
        @diff[:diff].each do |k, v|
          ks << k unless v.ignorable_deletion?
        end
      end
      ks
    end
    
    def ignorable_deletion?
      return @ignore_deletions && is_scalar_deletion? 
    end
    
    def is_scalar?
      return @diff[:is_scalar]
    end
    
    def is_scalar_deletion?
      return is_scalar? & (! no_diff? ) & (@diff[:right].nil? || @diff[:right].strip == '')
    end
    
    def indent 
      '  '
    end
    
    def summarize i='' 
      s = '' 

      if @diff[:left]      
        rem =  ignorable_deletion? ? 'keeping old value:        ' : 'removed: '
        val = @filter[:left] ? @filter[:left].call : @diff[:left].inspect
        s << i+rem+val+"\n"        
      end
      
      if @diff[:right]      
        add = ignorable_deletion? ? 'ignoring blank new value: ' : 'added:    '
        val = @filter[:right] ? @filter[:right].call : @diff[:right].inspect        
        s << i+add+val+"\n"
      end

      if (@diff[:diff])
        ii = i+indent
        @diff[:diff].each do |k,v|
          v.name = k
          next if v.ignorable_deletion? && @ign[k]
          s << i+indent+"- #{k}:"+v.summarize(ii+indent)
        end
      end
      s = '(none)' if (0==s.length)
      s = "\n"+s if /\n/ =~ s 
      return s
    end
    
    def dont_report_on_ignored_deletes(name)
      @ign[name] = 1
    end
  end #class
end #module

if $PROGRAM_NAME == __FILE__
 
  module Tests
    def self.t1
  
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
      puts "diff: "
      pp( d = (Hipe::StructDiff.diff(left,right)))
      puts "\n\n\n";
      print "summary----->\n"
      print d.summarize
      print "<------"
      print "done.\n"
    end
  
    def self.t2
      left = {
        :firstname=>'jake'
      }  
      right = {
        :firstname=>'sara'
      }
      d = Hipe::StructDiff.diff(left,right)
      d.filter_for(:firstname,:left){ "WANKERS" }      
      puts "Your diff: "
      pp d

      puts d.summarize
    end
  
  end
  Tests.__send__(ARGV[0])
end
