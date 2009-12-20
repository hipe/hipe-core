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
      @hlwoe_orig_fetch = method(:fetch)
      meta = class << self; self end
      
      meta.send(:define_method,:store) do |key,value|
        hlwoe_before_store(key,value)
        @hlwoe_orig_store.call(key,value)
      end
      
      meta.send(:define_method,:fetch) do |key|
        hlwoe_before_fetch(key)
        @hlwoe_orig_fetch.call(key)        
      end
    end
    def hlwoe_before_fetch(key)
      puts "\ncalling fetch!"
    end
    def hlwoe_before_store(key,value)
      puts "\ncalling store!"      
    end
  end
end
