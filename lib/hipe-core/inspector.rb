require 'pp'
module Hipe
  module Inspector      
    # PrettyPrint.pp() that returns a string instead (like puts) of print to standard out, 
    # like sprintf() is to printf().  prints info about where it was called from.
    def spp label, object
      # go backwards up the call stack, skipping caller methods we don't care about (careful!)
      # this is intended to show us the last interesting place from which this was called.
      i = line = methname = nil
      caller.each_with_index do |line,index|
        matches = /`([^']+)'$/.match(line)
        break if (matches.nil?) # almost always the last line of the stack -- the calling file name
        matched = /(?:\b|_)(?:log|ppp|spp)(?:\b|_)/ =~ matches[1]
        break unless matched
      end
      m = /^(.+):(\d+)(?::in `(.+)')?$/.match line
      raise CliException.new(%{oops failed to make sense of "#{line}"}) unless m
      path,line,meth = m[1],m[2],m[3]
      file = File.basename(path)
      PP.pp object, obj_buff=''
      
      # location = "(at #{file}:#{meth}:#{line})"
      location ="(at #{file}:#{line})"        
      if (location == @last_location)
        location = nil
      else 
        @last_location = location
      end
      
      buff = '';
      buff << label.to_s + ': ' if label
      buff << location if location
      buff << "\n" if (/\n/ =~ obj_buff)
      buff << obj_buff
      buff
    end      

    # don't change the name of this w/o reading spp() very carefully!
    def ppp symbol, object=nil, die=nil
      unless (symbol.instance_of?(Symbol) || symbol.instance_of?(String))
        die = object
        object = symbol
        symbol = 'YOUR VALUE'
      end
      
      puts spp(symbol, object)
      if die
        exit
      end
    end    
  end # Inspector
end # Hipe