require 'hipe-core/infrastructure/strict-attr-accessor'
require 'hipe-core/infrastructure/erroneous'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/struct/strict-set'
require 'hipe-core/io/all'

module Hipe
  module Io
    class GoldenHammer
      #
      # Warning: this class is experimental.   The exact spec for of 'data' is undefined and in flux.
      #
      # This is an all purpose response object that can be written to and read from in a variety of ways.
      # It should act like a string when you write to it as a string (a limited subset of string functionality)
      # It will act like an open data structure when you write to its data() acccessor
      # It knows whether or not it is valid? based on if it has any errors()
      # When you call to_s on it it will try to render the appropriate combination of these things
      # It can be merged with other GoldenHammers when possible, for example if you want to merge-in the
      # response to another golden hammer-responding function in your response.
      #
      include Hipe::Erroneous
      include Hipe::Io::BufferStringLike
      extend Hipe::StrictAttrAcccessor
      attr_reader :data, :string, :messages

      # @param name [String,Symbol]
      # This is a facility for subclasses or clients to use --
      # Depending on the client, it may be that the client is assuming the responsibility of rendering
      # this data structure, in which case a :suggested_template is just that, a suggestion of how to render this.
      # If the client is relying on GoldenHammer to render the response structure, (that is, golden_hammer.to_s)
      # then a suggested_template called :foo means that there is expected to be a method called "render_foo()"
      # that takes care of the (usu. ascii) rendering.  (The actual routing will happen in render_with_template())
      # which could be overridden if need be.)
      kind_of_setter_getter :suggested_template, String, Symbol


      # @param mixed [String,Hash]
      #   if String, equivalent to:
      #     out = GoldenHammer.new;
      #     out << mixed;
      #
      #   if Hash, expects there to be setters for each key in the hash, e.g.
      #     out = GoldenHammer.new :suggested_template => :tables
      #   is equivalent to:
      #     out = GoldenHammer.new
      #     out.sugested_template = :tables
      #
      def initialize(mixed = '')
        case mixed
        when String: start_str = mixed
        when Hash
          start_str = ''
          mixed.each do |key,value|
            send %{#{key}=}, value
          end
        else
          raise TypeError.new("Needed String or Hash had #{mixed.class.inspect}")
        end
        @data = OpenStructExtended.new
        @string = FlushingBufferString.new(start_str)
        @messages = []
        @template = nil
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
        if !valid?
          errors.map{|x| x.to_s} * '  '
        elsif @suggested_template
          render_with_suggested_template(@suggested_template)
        elsif @string.length > 0 || @messages.size > 0
          all_messages * "\n"
        else
          @string.to_s
        end
      end
      def render_with_suggested_template(template_name)
        send(%{render_#{template_name}})
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
