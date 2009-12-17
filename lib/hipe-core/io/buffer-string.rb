# IOString didn't have exactly what we wanted -- we wanted to be able
# to perform these same operations whether we are writing to $stdout our a string:
# thing.puts, thing.read, thing.<<
module Hipe
  module Io
    class BufferString < String # there was StringIO but i couldn't figure out how to use it      
      def read
        output = dup
        replace('')
        output
      end
      def puts mixed
        if mixed.kind_of? Array
          mixed.each{|x| puts x}
        else
          self << mixed
          self << "\n" if (mixed.kind_of? String and mixed.length > 0 and mixed[mixed.size-1] != "\n"[0]) #optparse does this btr
        end
      end      
    end
  end
end
