module Hipe
  module Erroneous
    def errors
      @errors ||= []
      @errors
    end
    def errors= enum
      @errors = []
      arr.each do |value|
        @errors << value
      end
    end
    def valid?
      !@errors || @errors.size == 0
    end
  end
end
