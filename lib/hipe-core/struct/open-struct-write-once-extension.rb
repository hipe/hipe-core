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
      if /=$/ =~ name.to_s
        my_name = name.to_s.chop.to_sym
        if @frozen[my_name]      
          raise TypeError.new %{can't write to frozen index "#{my_name}"}
        elsif @write_once[my_name]
          @orig_mm.call(name,*args)
          freeze_index! my_name
        else
          @orig_mm.call(name,*args)
        end
      else
        @orig_mm.call(name,*args)
      end
    end
    def open_struct_extension_init(orig_mm)
      @orig_mm = orig_mm
      @frozen = {}
      @write_once = {}
      class << self
        attr_accessor :table
      end
    end    
    def freeze_index!(key)
      key = key.to_sym
      meta = class << self; self end
      @frozen[key] = true
      meta.send :undef_method, :"#{key}="
    end
    def write_once! *list
      list.each do |key|
        key = key.to_sym
        if @table.has_key? key.to_sym
          freeze_index! key.to_sym
        else
          @write_once[key] = true
        end
      end    
    end
  end
end
