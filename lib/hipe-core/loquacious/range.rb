module Loquacious
  module RangeLike
    def self.[]=(range)
      throw TypeError.new("need range had #{range.inspect}") unless ::Range === range
      range.extend RangeLike
      range
    end
    
    def excludes?(value)
      if self === value
        false
      else
        if value < self.end
          %{below the minimum of #{self.begin}}
        else
          %{above the maximum of %{self.end}}
        end
      end
    end
  end
  class PartialRange
    include RangeLike
    attr_accessor :begin, :end
    def initialize(min,max,exclusive=false)
      @begin, @end, @exclusive = min, max, exclusive
    end
    def ===(thing)
      if @exclusive
        ((@begin && thing <  @begin) || (@end && thing > @end )) ? false : true
      else
        ((@begin && thing <= @begin) || (@end && thing >= @end )) ? false : true        
      end
    end
  end
  class Range < ::Range
    include RangeLike
  end
end
