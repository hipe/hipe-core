class BufferString < String # there was StringIO but i couldn't figure out how to use it
  def read
    output = self.dup
    self.replace('')
    output
  end
  def puts mixed
    if mixed.kind_of? Array
      mixed.each{|x| puts x}
    else
      self << mixed
      self << "\n" if (mixed.kind_of? String and mixed.length > 0 and mixed[mixed.size-1] != "\n"[0])
    end
  end
  public :puts
end