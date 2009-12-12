class Hipe::Range < Range
  def initialize(start,endo,exclusive=false)
    super start,endo,exclusive
  end
  def self.[]=(start,endo)
    return self.new(start,endo)
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
