require 'hipe-core/erroneous'
require 'hipe-core/open-struct-like'
require 'hipe-core/io/all'

module Hipe
  module Io
    class GoldenHammer
      include Hipe::Erroneous
      include Hipe::Io::BufferStringLike
      attr_reader :data, :string
      def initialize
        @data = {}
        @data.extend OpenStructLike
        @string = BufferString.new('')
      end
    end
  end
end  
