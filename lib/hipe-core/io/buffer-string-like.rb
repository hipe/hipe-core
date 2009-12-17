module Hipe
  module Io
    module BufferStringLike
      def <<(whatevs)
        string << whatevs
      end
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
          string << "\n" if (mixed.kind_of? String and mixed.length > 0 and mixed[mixed.size-1] != "\n"[0]) #optparse does this btr
        end
      end     
      def to_s
        string.to_s
      end
    end 
  end
end
