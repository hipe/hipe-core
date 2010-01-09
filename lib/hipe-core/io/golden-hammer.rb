require 'hipe-core/loquacious/all'
require 'hipe-core/infrastructure/erroneous'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/struct/strict-set'
require 'hipe-core/io/all'
require 'hipe-core/lingual/en/sentence-compression'

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
      extend Hipe::Loquacious::AttrAccessor
      attr_reader :data, :string, :messages

      # @param name [String,Symbol]
      # This is a facility for subclasses or clients to use --
      # Depending on the client, it may be that the client is assuming the responsibility of rendering
      # this data structure, in which case a :suggested_template is just that, a suggestion of how to render this.
      # If the client is relying on GoldenHammer to render the response structure, (that is, golden_hammer.to_s)
      # then a suggested_template called :foo means that there is expected to be a method called "render_foo()"
      # that takes care of the (usu. ascii) rendering.  (The actual routing will happen in render_with_template())
      # which could be overridden if need be.)
      attr_accessor :suggested_template, :compress_messages

      # passed to the OpenStructExtended when two objects are not equal and have the same name in the data field.
      # @see OpenStructExtended.  valid valiues are at least :raise and :pluralize, defaults to :pluralize
      attr_accessor :on_data_collision


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
        @on_data_collision = :pluralize
        @compress_messages = false
        @messages = []
        @data = OpenStructExtended.new
        @template = nil
        case mixed
        when String
          @string = FlushingBufferString.new mixed
        when Hash
          @string = FlushingBufferString.new ''
          mixed.each do |key,value|
            send %{#{key}=}, value
          end
        else
          raise ArgumentError.new("Needed String or Hash had #{mixed.class.inspect}")
        end
        @data._set(:on_collision, @on_data_collision)
      end
      def merge!(other)
        unless other.kind_of? GoldenHammer
          raise ArgumentError.new("GoldenHammer can only merge w/ another GoldenHammer, not #{other.inspect}")
        end
        @string << other.string
        concat_these_messages other.messages
        self.errors.concat other.errors
        @data.deep_merge_strict! other.data
      end
      def concat_these_messages messages
        if @compress_messages
          unless @messages.kind_of?(Hipe::Lingual::En::SentenceCompression)
            cmp = Hipe::Lingual::En::SentenceCompression.new
            @messages.each { |message| cmp << message }
            @messages = cmp
          end
          messages.each do |message|
            @messages << message
          end
        else
          @messages.concat other.messages
        end
      end

      # assumes ascii context
      def to_s
        if !valid?
          errors.map{|x| x.to_s} * '  '
        elsif @suggested_template
          render_with_suggested_template(@suggested_template)
        elsif @string.length > 0 || @messages.size > 0
          render_all_messages
        else
          @string.to_s
        end
      end
      def render_all_messages
        if (@compress_messages)
          lines = []
          lines << @string.to_s if (@string.length > 0)
          if @messages.size > 0
            lines << (@messages.respond_to?(:say) ? @messages.say : @messages.join("\n"))
          end
          lines.join("\n")
        else
          all_messages * "\n"
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
      def data= mixed
        raise ArgumentError.new("won't clobber existing data!") unless @data._table.size == 0
        case mixed
          when Hash then @data = OpenStructExtended.new(mixed)
          else raise ArgumentError.new("Expecting Hash has #{mixed.class}")
        end
      end
      def message= mixed
        raise ArgumentError.new("cannot convert #{mixed.class} to String!") unless mixed.respond_to? :to_str
        raise ArgumentError.new("won't clobber existing messages!") unless @messages.size == 0
        @messages << mixed
      end
      def error= mixed
        raise ArgumentError.new("won't clobber existing errors!") unless errors.size == 0
        self.errors << mixed
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
