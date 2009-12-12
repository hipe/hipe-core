require 'rubygems'
require 'pp'

# Usage: diff = StructDiff::diff(hash1, hash2)
# puts diff.summarize
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
        when Symbol: true
        else false
      end
    end

    protected
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
    end
    public

    def middle_diff
      @diff[:diff]
    end

    def right
      @diff[:right]
    end

    def filter_for(field,hand,&proc)
      @filter ||= {}
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

    def self.diff obj1, obj2, opts={}
      diff = _diff(obj1,obj2)
      if (opts[:sort])
        require 'orderedhash'
        diff.to_oh_recursive!
      end
      diff
    end

    def self.hash_to_oh_recursive(hash)
      oh = OrderedHash.new
      hash.keys.sort{|a,b| a.to_s <=> b.to_s}.each do |k|
        if Hash===hash[k]
          oh[k] = hash_to_oh_recursive(hash[k])
        elsif StructDiff===hash[k]
          hash[k].to_oh_recursive!
          oh[k] = hash[k]
        else
          oh[k] = hash[k]
        end
      end
      oh
    end

    def to_oh_recursive!
      [:right,:left,:same,:diff].each do |which|
        if Hash === @diff[which]
          @diff[which] = self.class.hash_to_oh_recursive(@diff[which])
        end
      end
    end

    def self._diff obj1, obj2
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
        return compare_arrays(obj1,obj2)
      elsif (obj1.kind_of? Hash)
        return compare_hashes(obj1,obj2)
      else
        raise Exception.new(%{unhandled case: "#{obj1.class}" and "#{obj2.class}"});
      end
    end

    # a bit arbitrary how we do it.  What we really need is LCS!
    # what we do is get the left and right diff.  shared elements
    # from a set memebership persective, if they don't appear in the same
    # order in left and right, we blow up.
    #
    def self.compare_arrays(arr1,arr2)
      left_extra = arr1 - arr2
      right_extra = arr2 - arr1
      union = arr1 & arr2           # the one on the left determines order
      compare_order = arr2 & union  # the one on the left determines order
      if (compare_order != union)
        raise Exception.new("Structdiff doesn't yet have LCS to compare these two arrays.")
      end
      no_diff = (left_extra.size + right_extra.size == 0)
      ret = {}
      ret[:no_diff] = true if (no_diff)
      ret[:left] = left_extra if left_extra.size > 0
      ret[:right] = right_extra if right_extra.size > 0
      ret[:same] = union if (union.size > 0)
      return self.new ret
      # we could make this more sophisticated in the future!
    end

    def self.compare_hashes(obj1,obj2)
      hashs = {:left => obj1,:right => obj2}
      keys = {
        :left  => (obj1.keys - obj2.keys),
        :right => (obj2.keys - obj1.keys)
      }
      ret = {}
      [:left,:right].each { |hand|
        if keys[hand].length > 0
          partial_hash = hashs[hand].clone
          partial_hash.delete_if{|k,v| !keys[hand].include? k }
          if (partial_hash.size > 0)
            ret[hand] = partial_hash
          end
        end
      }
      same = (obj1.keys & obj2.keys)
      all_shared_keys_have_same_values = true
      middle = {
        :diff => {},
        :same => {}
      }
      same.each do |k|
        subdiff = _diff(obj1[k],obj2[k])
        if (subdiff.no_diff?)
          middle[:same][k] = subdiff
        else
          all_shared_keys_have_same_values = false
          middle[:diff][k] = subdiff
        end
      end
      [:diff,:same].each do |k|
        if middle[k].size > 0
          ret[k] = true ?  middle[k] : middle[k]
        end
      end
      if (all_shared_keys_have_same_values && keys[:left].size == 0 && keys[:right].size == 0 )
        ret[:no_diff] = true
      end
      return self.new ret
    end

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

    def diff?; ! no_diff? end

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
        val = (@filter && @filter[:left]) ? @filter[:left].call : @diff[:left].inspect
        s << i+rem+val+"\n"
      end

      if @diff[:right]
        add = ignorable_deletion? ? 'ignoring blank new value: ' : 'added:    '
        val = (@filter && @filter[:right]) ? @filter[:right].call : @diff[:right].inspect
        s << i+add+val+"\n"
      end

      if (@diff[:diff])
        ii = i+indent
        @diff[:diff].each do |k,v|
          v.name = k
          next if v.ignorable_deletion? && @ign && @ign[k]
          s << i+indent+"- #{k}:"+v.summarize(ii+indent)
        end
      end
      s = '(none)' if (0==s.length)
      s = "\n"+s if /\n/ =~ s
      return s
    end

    def dont_report_on_ignored_deletes(name)
      @ign ||= {}
      @ign[name] = 1
    end
  end #class
end #module
