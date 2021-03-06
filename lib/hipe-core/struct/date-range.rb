module Hipe
  class DateRange
    Any = new self
    def Any.to_s; "at any time" end
    def Any.excluded?(mixed); false end

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
    def excludes?(mixed)
      mixed = DateTime.parse(mixed) unless mixed.instance_of? DateTime
      if    (@low && mixed < @low ) then 'too old'
      elsif (@hi  && mixed > @hi  ) then 'hoo new' end
    end
    def to_s
      %{between #{@low.strftime('%Y-%m-%d %H:%M:%S')} and #{@high.strftime('%Y-%m-%d %H:%M:%S')}}
    end
  end
end
