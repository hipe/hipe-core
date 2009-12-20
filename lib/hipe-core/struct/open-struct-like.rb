require 'hipe-core'
require 'ostruct'
module Hipe
  module OpenStructLike
    # makes a hash also act a little like an OpenStruct
    #
    # The idea is to allow fetch and store to look either hash-like or OpenStruct like
    #
    # NO: To acheive this, requests to fetch and store are routed through an OpenStruct,
    # NO: which internally uses this object as its internal table
    #
    # The behavior is undefined if you extend things other than hashes
    # with this.  But it is expected only to need to define fetch() and store() (and their aliases [] and []=)
    #
    # warning - You will not be able to use a field named 'table',
    # or any of the other instance methods defined here.
    #
    class << self
      def enhance(hash,thing=nil)
        hash.extend self
        hash.open_struct_like_init(thing)
        hash
      end
      alias_method :[], :enhance
    end

    attr_reader :table
    def open_struct_like_init(thing=nil)
      @open_struct = OpenStruct.new
      use_this_table = thing.nil? ? self : thing
      [:[], :[]=, :fetch, :store].each do |meth|   # expensive check, for development only ?
        raise Hipe::Exception.new(%{Can't OpenStructLike.enchance() "#{thing.inspect}" - it must have []}) unless
          use_this_table.respond_to? meth
      end
      @open_struct.instance_variable_set('@table',use_this_table)  # hack
      @table = use_this_table
      nil
    end

    def method_missing(method_name, *args)
      @open_struct.method_missing(method_name, *args)
    end

    #def fetch(key)
    #  @open_struct.send(key.to_sym)
    #end
    #def store(key,value)
    #  @open_struct.send(%{#{key}=}, value)
    #end
  end
end
