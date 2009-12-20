require 'ostruct'

module Hipe
  module OpenStructWriteOnceExtension
    #
    # Warning - we are considering making this an extension for a plain old hash instead,
    # and then using it internally in an OrderedHash and/or OpenStruct
    #    
    # With some data structures it is useful to assert that certain elements only
    # get written zero or one time -- that is that that element is never clobbered.
    # This mixin gives that ability to an OpenStruct.
    #
    # For example, maybe for some reason you are parsing a file of a certain format,
    # and the file has records for books, and for each book, you want to assert
    # that there is only one 'title' for that record
    #
    #     o = Hipe::OpenStructWriteOnceExtension[OpenStruct.new]
    #     o.write_once! :title
    #
    #     o.title = "Behavior-centric client-side MVC with Jhaskell"
    #     o.title = "something else"    #=> throws a TypeError: "can't write to frozen index 'title'"
    #
    # If you want to assert that any and all fields in the struct are only ever written once,
    #
    #     o.write_once!
    #
    # If you want to have more fine-grained control of the behavior on clobber,
    # you can define a handler for it, with
    #
    #     o.on_clobber{ |field_name| raise MyException.new(%{#{field_name} is already set.}) }
    #
    # At present, the above is only available for object-wide write-once struct, and not clobbers
    # per field.


    #include OpenStructCommonExtension
    def self.[](ostruct)
      proc = ostruct.method :method_missing
      ostruct.extend self
      #ostruct.open_struct_common_extension_init()
      ostruct.open_struct_write_once_extension_init(proc)
      ostruct
    end
    def self.new(hash=nil)
      ret = OpenStruct.new(hash)
      self[ret]
    end
    def on_clobber &block
      raise TypeError("must providve block") unless block
      @on_clobber = block
    end
    def method_missing(name,*args)
      if /=$/ =~ name.to_s
        my_name = name.to_s.chop.to_sym
        if @frozen[my_name]
          if (@on_clobber)
            return @on_clobber.call(name)
          else
            raise TypeError.new %{can't write to frozen index "#{my_name}"}
          end
        elsif true==@write_once or @write_once[my_name]
          @orig_mm.call(name,*args)
          freeze_index! my_name
        else
          @orig_mm.call(name,*args)
        end
      else
        @orig_mm.call(name,*args)
      end
    end
    def open_struct_write_once_extension_init(orig_mm)
      @orig_mm = orig_mm
      @frozen = {}
      @write_once = {}
    end
    def freeze_index!(key)
      key = key.to_sym
      meta = class << self; self end
      @frozen[key] = true
      # it's possible that people are using OpenStructLike and not OpenStuct, and circumventing method creation.
      if self.respond_to?(:"#{key}=")
        meta.send :undef_method, :"#{key}="
      end
    end
    def write_once! *list, &block
      if (list.size == 0)
        @write_once = true
        @on_clobber = block if block
      else
        raise TypeError.new(%{blocks can only be provided if setting the whole object to write_once!}) if block
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
end
