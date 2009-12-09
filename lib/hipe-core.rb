module Hipe
  class Exception < ::Exception
    def self.factory(string,details={})
      extra = (details.size > 0) ? %{ #{details.inspect}} : ''
      return self.new(%{#{string}#{extra}})
    end
  end
end