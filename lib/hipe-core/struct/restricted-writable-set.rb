require 'hipe-core/lingual/en'
require 'set'

module Hipe
  class RestrictedWritableSet < SortedSet
    include Lingual::English    
    def initialize(list,&block)
      @whitelist = Set.new list, &block
      super([])
    end
    def merge(enum)
      theirs = Set.new(enum)
      if theirs.proper_subset? self
        super
      else
        set = self
        s1 = en{sp(np('invalid value',set.map))}.say.capitalize
        s2 = en{sp(np('valid value',set.map))}.say.capitalize
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
  end
end
