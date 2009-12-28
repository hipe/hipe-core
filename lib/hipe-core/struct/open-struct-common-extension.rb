# bacon spec/struct/spec_open-struct-common-extension.rb
module Hipe
  module OpenStructCommonExtension
    # Adds a few things things to OpenStruct that you wish it had, like member variable reflection.
    #
    # Usage:
    #     o = Hipe::OpenStructCommonExtension[OpenStruct.new]
    #     o.author_name = 'murakami'
    #     puts o.author_name        #=>
    #     puts o[:author_name]      #=> 'murakami'
    #     o._table.keys              #=> [:author]
    #     o._table.size              #=> 1
    #
    # Note: Any method that's defined here, your data member can't have such a field name, e.g. '_table'
    #
    # Warning: this overrides the encapsulation that Openstruct gives its internal hash.
    # This makes is fragile both because the OpenStruct implementation might change,
    # and you will get unpredictable results if you change the internal table willy-nilly.
    # So if you use my_open_struct.table, don't alter it unless you want pain
    #
    def self.[](ostruct)
      ostruct.extend self unless self === ostruct
      ostruct.open_struct_common_extension_init
      ostruct
    end
    def [](key)
      raise TypeError, %{symbols or strings keys only, not #{key.inspect}} unless String===key or Symbol===key
      send(key)
    end
    def []=(key,value)
      raise TypeError, %{symbols or strings keys only, not #{key.inspect}} unless String===key or Symbol===key
      send(%{#{key}=}, value)
    end
    def use_ordered_hash!
      require 'orderedhash'
      raise "use_ordered_hash! must happen before you add any values" unless @table.size == 0
      @table = OrderedHash.new()
    end
    def merge!(hash)
      raise TypeError.new("need hash have #{hash.inspect}") unless hash.kind_of? Hash
      hash.each{|key,value| self[key] = value}
      self
    end

    protected
    def self.deep_merge_strict!(hash1, hash2, path)
      middle = hash1.keys & hash2.keys
      right = hash2.keys - hash1.keys
      right.each do |key|
        hash1[key] = hash2[key]
      end
      i = path.size
      path.push(nil)
      middle.each do |key|
        path[i] = key
        left = hash1[key]; right = hash2[key]
        if left.class != right.class
          throw :FAIL, "won't compare elements of different classes: #{left.class} and #{right.class}"
        elsif (left.kind_of?(Hash) || left.kind_of?(OpenStructCommonExtension))
          if (left.kind_of?(OpenStructCommonExtension))
            left = left._table
            right = right._table
          end
          deep_merge_strict!(left, right, path)
        elsif(left.kind_of?(Array) || left.kind_of?(String))
          left.concat right
        elsif(left == right) # we might add an option for adding Fixnums and Floats
          next
        else
          throw :FAIL, "collision of elements that were not equal: #{left.inspect} and #{right.inspect}"
        end
      end
      path.pop
    end
    public

    def deep_merge_strict!(os)
      raise TypeError.new("need OpenStructCommonExtension have #{os.inspect}") unless
        os.kind_of? OpenStructCommonExtension
      path = []
      fail = catch(:FAIL) do
        OpenStructCommonExtension.deep_merge_strict!(@table, os._table, path)
        false
      end
      if (fail)
        raise ArgumentError.new(%{#{fail} at "#{path.map{|x| x.inspect}*'/'}"})
      end
    end

    [:delete,:each,:has_key?].each do |name|    # :values :keys,
      define_method(name){ |*args, &block| @table.send(name,*args,&block) }
    end

    def to_hash; @table.dup end
    def open_struct_common_extension_init
    end

    # use this at your own risk!!!
    # crappy name b/c the namespace of os should in theory by wide open (it's not)
    def _table; @table end

    # just for testing ?
    def symbolize_keys_of(hash)
      hash2 = {}
      hash.each {|k,v| hash2[k.to_sym] = v}
      hash2
    end
  end
end
