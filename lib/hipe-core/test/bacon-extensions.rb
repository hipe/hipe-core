module Hipe
  module Test
    module Bacon
      class NoticeStream < IO
        def self.get(stack)
          self.new($stdout.to_i,stack)
        end
        def initialize(fd,stack)
          super(fd)
          @caller_line = stack.shift
        end
        def write(data)
          caller_line = caller[3]
          super(%{\n>> #{data} (#{File.basename(caller_line)})})
          flush # if we don't call this it gets flushed at the end of the tests
        end
      end
    end
  end
end
module Bacon
 class Context
   def skipit(description, &block)
     puts %{- SKIPPING #{description}}
   end
   #
   # @experimental
   #
   # create an output stream used for writing notices during tests.
   def notice_stream()
     Hipe::Test::Bacon::NoticeStream.get(caller)
   end
  end
end
