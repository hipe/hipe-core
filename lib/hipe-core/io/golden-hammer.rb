require 'hipe-core/infrastructure/erroneous'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/io/all'

module Hipe
  module Io
    class GoldenHammer
      # Warning: this class is experimental.   The exact spec for of 'data' is undefined and in flux.
      #
      # This is an all purpose response object that can be written to and read from in a variety of ways.

      include Hipe::Erroneous
      include Hipe::Io::BufferStringLike
      attr_reader :data, :string, :messages
      def initialize
        @data = OpenStructExtended.new
        @string = BufferString.new('')
        @messages = []
      end
      def merge!(other)
        raise TypeError("GoldenHammer can only merge w/ another GoldenHammer, not #{other.inspect}") unless
          other.kind_of?(GoldenHammer)
        @string << other.string
        @messages.concat other.messages
        @data.deep_merge_strict! other.data
      end
      # assumes ascii context
      def to_s
        if (!valid?)
          errors.map{|x| x.to_s} * '  '
        elsif (@string.length > 0 || @messages.size > 0)
          all_messages * "\n"
        else
          inspect
        end
      end
      def all_messages
        messages = @messages.dup
        messages.unshift(@string) if @string.length > 0
        messages
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
