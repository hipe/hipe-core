module Hipe
  module Core
    VERSION = '0.0.1'
  end
  class Exception < ::Exception;
    attr_accessor :details
    def initialize(string,details=nil)
      @details = details || {}
      super(string)
    end
  end
end
# keep it light and simple in here!  weird stuff can go in its own file.
