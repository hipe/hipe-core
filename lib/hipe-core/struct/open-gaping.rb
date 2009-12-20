module Hipe
  class Gaping
    attr_reader :children
    attr_reader :emtpy
    alias_method :emtpy?, :emtpy
    alias_method :nil?, :emtpy
    def initialize
      @empty = true
    end
    def init_child(parent)
      @parent = parent
    end
    def method_missing(name,*args)
      if /=$/ =~ name
        @chilren[name] = args[1]
        @empty = args[1].nil?
      else
        unless(@children.has_key?(name))
          @children[name] = self.class.new
        end
        @children
      end
    end
  end
end
