require 'hipe-core/io/buffer-string'
require 'hipe-core/struct/strict-set'
module Hipe
  module Io
    class FlushingBufferString < BufferString
      # Allows you to add to a list of streams to flush to at certain points
      # the default is to flush after each puts! and each call to flush!
      # these defaults won't be changeable until we add a whitelist accessor on StrictSet @todo
      # @see Hipe::Io::BufferString for appologies to StringIO
      attr_reader :flush_after, :flush_to
      
      def initialize str=''
        super str
        @flush_after = StrictSet.new([:puts])
        @flush_after.merge([:puts])
        @flush_to = []
      end

      def puts *args
        super(*args)
        if @flush_after.include? :puts
          flush!
        end
      end
      def flush!
        return nil unless @flush_to.size > 0
        readed = read
        size = readed.length
        @flush_to.each do |io|
          io.write readed
          io.flush
        end
        size
      end
    end
  end
end
      