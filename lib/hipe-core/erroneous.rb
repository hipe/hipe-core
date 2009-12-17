module Hipe
  module Erroneous
    def errors
      @errors ||= []
      @errors
    end
    def valid?
      !@errors || @errors.size == 0
    end
  end
end
