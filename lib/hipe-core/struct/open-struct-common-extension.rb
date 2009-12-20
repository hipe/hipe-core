module Hipe
  module OpenStructCommonExtension
    # Adds a few things things to OpenStruct that you wish it had, like member variable reflection.
    #
    # Usage:
    #     o = Hipe::OpenStructCommonExtension[OpenStruct.new]
    #     o.author_name = 'murakami'
    #     puts o.author_name        #=>
    #     puts o[:author_name]      #=> 'murakami'
    #     o.table.keys              #=> [:author]
    #     o.table.size              #=> 1
    #
    # Note: Any method that's defined here, your data member can't have such a field name, e.g. 'table'
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
      raise TypeError, %{symbols or strings keys only, not #{key}} unless String===key or Symbol===key
      send(key)
    end
    def []=(key,value)
      raise TypeError, %{symbols or strings keys only, not #{key}} unless String===key or Symbol===key
      send(%{#{key}=}, value)
    end
    def use_ordered_hash!
      require 'orderedhash'
      @table = OrderedHash.new(@table)
    end
    def open_struct_common_extension_init
      class << self
        attr_accessor :table
      end
    end
  end
end
