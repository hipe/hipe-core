module Hipe
  class DateRange
    def self.[](mixed)
      return nil if mixed.nil?
      return DateRange.new(mixed[0],mixed[1])
    end
    def initialize(low,hi)
      @low = low ? DateTime.parse(low) : nil
      @hi  = hi  ? DateTime.parse(hi)  : nil 
      raise HipeException.factory(%{Failed to create date range from "#{low}" and "#{hi}"},:type=>:core_date_range) if      
        (@low.nil? and @hi.nil?)
    end
    def outside?(mixed)
      mixed = DateTime.parse(mixed) unless mixed.instance_of? DateTime
      if    (@low && mixed < @low ) then 'too old' 
      elsif (@hi  && mixed > @hi  ) then 'hoo new' end
    end
  end
end
