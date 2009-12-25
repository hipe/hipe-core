require 'hipe-core/infrastructure/erroneous'
require 'hipe-core/struct/open-struct-like'
require 'hipe-core/io/all'

module Hipe
  module Io
    class GoldenHammer
      include Hipe::Erroneous
      include Hipe::Io::BufferStringLike
      attr_reader :data, :string
      def initialize
        @data = {}
        OpenStructLike.enhance(@data)
        @data.extend OpenStructLike
        @string = BufferString.new('')
      end
      def self.[](mixed)
        response = self.new
        if (Exception===mixed)
          response.errors << mixed
        elsif (String===mixed)
          response << mixed
        else
          response.data[:mixed] = mixed
        end
        response
      end
    end
  end
end
