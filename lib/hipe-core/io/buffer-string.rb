# IOString didn't have exactly what we wanted -- we wanted to be able
# to perform these same operations whether we are writing to $stdout our a string:
# thing.puts, thing.read, thing.<<
module Hipe
  module Io
    module BufferStringLike
      def read
        output = string.dup
        string.replace('')
        output
      end
      def puts mixed
        if mixed.kind_of? Array
          mixed.each{|x| string.puts x}
        else
          string << mixed
          string << "\n" if (mixed.kind_of? String and mixed.length > 0 and mixed[mixed.size-1] != "\n"[0])
        end
      end      
    end
    class BufferString < String # there was StringIO but i couldn't figure out how to use it
      include BufferStringLike
      def string
        return self
      end
    end
  end
end
