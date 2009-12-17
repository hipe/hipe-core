require 'ostruct'
# makes a hash also act like a read-only OpenStruct
module Hipe
  module OpenStructLike
    def self.[](hash)
      hash.extend self
      hash.init_open_struct_like
      hash
    end
    def init_open_struct_like
      @open_struct = OpenStruct.new
      @open_struct.instance_variable_set('@table',self)
    end
    def method_missing(method_name, *args)
      @open_struct.method_missing(method_name, *args)
    end
  end
end
