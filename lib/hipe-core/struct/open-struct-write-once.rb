# Set certain elements of an OpenStruct to be write once only
# A TypeError is thrown
module Hipe
  module OpenStructWriteOnceExtension
    def self.[](ostruct)
      proc = ostruct.method :method_missing
      ostruct.extend self
      ostruct.open_struct_extension_init(proc)
      ostruct
    end
    def method_missing(name,*args)
      name = name.to_s
      if /=$/ =~ name and @frozen[name.chop]      
        raise TypeError.new %{can't write to a frozen index}
      else
        @orig_mm.call(name.to_sym,*args)
      end
    end
    def open_struct_extension_init(orig_mm)
      @orig_mm = orig_mm
      @frozen = {}
      class << self
        attr_accessor :table
      end
    end    
    def no_clobber! *list
      meta = class << self; self end
      list.each do |x|
        @frozen[x.to_s] = true
        s = :"#{x}="
        meta.send :undef_method, s
        
      end    
    end
  end
end
