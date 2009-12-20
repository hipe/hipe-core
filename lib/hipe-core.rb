module Hipe
  module Core
    VERSION = '0.0.3'
  end

  module Io;      end
  module Lingual; end

  class Exception < ::Exception
    attr_accessor :details
    def initialize(*args)
      string = args.size > 0 ? (String === args[0] ? args.shift : nil ) : nil
      @details = case args.size
        when 0 then {}
        when 1 then args[0].respond_to?(:[]) ? args[0] : {args[0].class => args[0]}
        else {Array => args}
      end
      super(string)
    end
    def self.[](*args)
      return Exception.new(*args)
    end
  end
end
# keep it light and simple in here!  weird stuff can go in its own file.
