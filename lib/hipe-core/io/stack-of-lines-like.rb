# abstract a file into a stack (or stream) of lines that you can either "peek" or "pop"
# maybe look at the FileString library that apeiros was working on  
# close the file when you get to the last line  

# should check out github/apeiros/FileString and killerfox/File::Tie (Tie::File)

require 'hipe-core/io'  # for Exception

module ::Hipe::Io::StackOfLinesLike 
  def self.[](io)
    if (IO === io)
      io.extend self
      io.sol_init
      ret = io
    elsif (String === io)
      fh = File.open(io,'r')
      ret = self[fh]
    else
      sol_raise %{#{self}[] must take an IO or a filename, not #{io.inspect}}
    end
    ret
  end

  def pop
    ret = @peek
    self.sol_update_peek unless @peek.nil?
    ret
  end
  
  def sol_init # tried making this protected but no
    class << self
      attr_reader :peek
    end
    sol_raise "must be an open filehandle" unless (File === self && !closed?)
    sol_update_peek
  end  

  protected 
  
  # "next" is such a common name we don't want to clobber it on some future other object  
  # although we are clobbering "peek()" (and @peek) because its too concise not to.
  def sol_update_peek
    @peek = gets 
    close if @peek.nil?
  end
  
  def sol_raise(msg,details={})
    raise Hipe::Exception.factory(msg,details)
  end
end