require 'hipe-core/lingual/en'
require 'set'

module Hipe
  class StrictSet < Set  # was SortedSet but we would have to mess w/ rb tree
    include Lingual::English
    def initialize(enum,&block)
      super(nil)
      # strange -- the above clears the instance variable "@whitelist" and sets it to an empty set. used internally?
      @my_whitelist = Set.new enum, &block
    end
    def merge(enum)
      if enum.to_set.subset? @my_whitelist
        super
      else
        whitelist = @my_whitelist
        s1 = en{sp(np('invalid value',enum.map{|x| x.inspect}))}.say.capitalize
        s2 = en{sp(np('valid value', whitelist.map{|x| x.inspect}, :say_count=>false))}.say.capitalize
        raise ArgumentError.new(%{#{s1}.  #{s2}.})
      end
    end
    def add(o)
      merge([o].to_set)
    end
    def add?(o)
      return nil if include? o
      add(o)
    end
    def inspect
      spr = super
      add = @my_whitelist.inspect
      #<Set: {:b, :a}>
      add.gsub!(/>$/,'')
      add.gsub!(/^#<Set: /,'@whitelist: ')
      spr.gsub!(/>$/, " #{add}>")
      spr
    end
  end
end
