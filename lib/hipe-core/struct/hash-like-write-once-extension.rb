module Hipe
  module HashLikeWriteOnceExtension
    # With some data structures it is useful to assert that certain elements only
    # get written zero or one time -- that is that that element is never clobbered.
    # This mixin gives that ability to an OpenStruct.
    #
    # @see Hipe::OpenStructLikeWriteOnceExtension, which this is based off of
    #
    # For example, maybe for some reason you are parsing a file of a certain format,
    # and the file has records for books, and for each book, you want to assert
    # that there is only one 'title' for that record
    #
    #     h = Hipe::HashLikeWriteOnceExtension[Hash.new]
    #     h.write_once! :title
    #
    #     h[:title] = "Behavior-centric client-side MVC with Jhaskell"
    #     h[:title] = "something else"    #=> throws a TypeError: "can't write to frozen index 'title'"
    #
    # If you want to assert that any and all fields in the struct are only ever written once,
    #
    #     h.write_once!
    #
    # If you want to have more fine-grained control of the behavior on clobber,
    # you can define a handler for it, with
    #
    #     h.on_clobber{ |field_name| raise MyException.new(%{#{field_name} is already set.}) }
    #
    # At present, the above is only available for object-wide write-once struct, and not clobbers
    # per field.
    #

    def self.[](table)
      table.extend self
      table
    end

    def self.extended(obj)
      obj.hash_like_write_once_extension_init
    end

    def hash_like_write_once_extension_init
      @hlwoe_orig_store = method(:store)
      @on_clobber_any = nil      
      @on_clobber = {}  
      @frozen = {}
      @write_once = {}
      meta = class << self; self end
      meta.send(:define_method,:store) do |key,value|        
        hlwoe_store(key,value)
      end
      meta.send(:alias_method, :[]=, :store)
    end

    def hlwoe_store(key,value)
      if @frozen[key]
        clobbering_time = (@on_clobber[key] || @on_clobber_default)
        return self.instance_exec(key, value, &clobbering_time)
      elsif (true==@write_once or @write_once[key])
        @hlwoe_orig_store.call(key,value) # if this for some reason throws, we don't record the write
        freeze_index! key
      else
        @hlwoe_orig_store.call(key,value)
      end
    end
    
    def write_once! *list, &block
      if (list.size == 0)
        @write_once = true
        @on_clobber_default = block || on_clobber_default_default
      else
        @on_clobber ||= {}
        @write_once = {} unless Hash === @write_once
        list.each do |key|
          if has_key? key
            freeze_index! key
          else
            @write_once[key] = true
          end
          @on_clobber[key] = block || on_clobber_default_default          
        end
      end
    end
    
    def on_clobber_default_default
      @on_clobber_default_default ||= lambda{|key,value|
        raise TypeError.new(%{can't overwrite frozen position #{key.inspect} of #{self.class}})
      }
    end
    
    def freeze_index!(key)
      @frozen[key] = true
    end
  end
end
