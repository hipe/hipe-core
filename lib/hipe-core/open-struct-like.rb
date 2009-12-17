require 'hipe-core'
require 'ostruct'
# makes a hash also act like a read-only OpenStruct
module Hipe
  module OpenStructLike
    def self.enhance(hash,thing=nil)
      hash.extend self
      hash.init_open_struct_like(thing)   
      hash
    end    
    class << self
      alias_method :[], :enhance
    end
    def init_open_struct_like(thing=nil)
      @open_struct = OpenStruct.new
      use_this_table = thing.nil? ? self : thing
      raise Hipe::Exception.new(%{Can't OpenStructLike.enchance() "#{thing.inspect}" - it must have []}) unless
        use_this_table.respond_to? :[]
      @open_struct.instance_variable_set('@table',use_this_table)
    end
    def method_missing(method_name, *args)
      @open_struct.method_missing(method_name, *args)
    end
  end
end
