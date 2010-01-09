# bacon spec/struct/spec_table.rb
require 'hipe-core'
require 'hipe-core/loquacious/all'
require 'hipe-core/io/buffer-string'
require 'hipe-core/lingual/ascii-typesetting'
require 'hipe-core/struct/hash-like-with-factories'
require 'hipe-core/struct/hash-like-write-once-extension'
require 'hipe-core/lingual/en'
require 'orderedhash'

module Hipe
  class Table

    # Hipe::Table is an abstract representation of a table intended to allow:
    #  - dynamic addition and removal of rows and columns
    #    - at runtime you may not want to show certain columns based on some criteria
    #  - a representation of the data abstract enough so that it can be used in different view contexts, e.g.
    #    - to render ascii output to a terminal
    #    - to render html, xml, csv, json, yaml, etc
    #
    #  (the reason we made a class for it was because we kept changing the implementation in GoldenHammer --
    #  Not sure what combination of Set, SortedSet, OrderedHash (molic), AS3 OrderedHash, OpenStruct or Mash
    #  we will eventually use, so we needed to insulate the implementation from some kind of spec for this.)
    #
    #  Despite MVC wisdom, Hipe::Table will provide a default renderer for :ascii contexts


    extend Loquacious::AttrAccessor
    include Lingual::English

    class Renderers < HashLikeWithFactories
      # added to below
    end

    protected
      def initialize
        @fields = []
        @fields_by_name = {}
        @show_header = nil
        @renderers = Renderers.new
      end

      def self.humanize_lite(str)
        str.to_s.gsub('_',' ')
      end

    public
    attr_accessor :fields
    attr_reader :list
    block_accessor :labelize
    boolean_accessor :visible
    boolean_accessor :show_header, :nil => true
    enum_accessor :axis, [:horizontal, :vertical]
    string_accessor :name, :nil => true
    kind_of_accessor :renderers, Renderers

    def self.make &block
      t = self.new
      t.instance_eval(&block)
      t.labelize ||= lambda{ |field_name| humanize_lite(field_name) }
      t
    end

    def visible_fields
      fields.select{|f| f.visible? }
    end

    def show_only *list
      (@fields_by_name.keys - list).each do |name|
        self.field_or_raise(name).hide()
      end
      list.each do |name|
        self.field_or_raise(name).show()
      end
    end

    def show_all
      @fields.each{|x| x.show}
      true
    end

    def field(*args,&block)
      if block
        f = Field.new(self,*args,&block)
        if @fields_by_name[f.name]
          raise ArgumentError.new("For now, can't redefine fields: #{f.name.inspect}")
        end
        @fields << f
        @fields_by_name[f.name] = f
      else
        raise ArgumentError.new("use field() either to define a field or access one") unless args.size == 0
        @fields_by_name
      end
    end

    def field_or_raise name
      unless ret = @fields_by_name[name]
        raise ArgumentError.new("No such field #{name.inspect}")
      end
      ret
    end

    def list=list
      raise TypeError.new("list must be enumerable") unless list.kind_of? Enumerable
      @list = list
    end

    def renderer(*args)
      if block_given?
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 1) ") unless (args.size == 1)
        name = args[0]
        instance_existed = @renderers.has_instance?(name)
        renderer = @renderers[name]
        if (renderer.nil?)
          available_renderers = @renderers.keys.map{|k| k.inspect}
          raise ArgumentError.new("Sorry, no such renderer #{name.inspect}. "<<
            en{ sp(np('available','renderer'),available_renderers) }.say() )
        end
        yield renderer
        nil
      else
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 0) ") unless (args.size == 0)
        @renderers.accessor
      end
    end

    def render(renderer_name)
      if (:horizontal==@axis && ! (renderer_name.to_s =~ /_horizontal$/))
        renderer_name = %{#{renderer_name}_horizontal}.to_sym
      end
      renderer[renderer_name].render(self)
    end

    class Field
      extend Loquacious::AttrAccessor
      symbol_accessor :name
      boolean_accessor :visible
      integer_accessor :min_width, :min=>1
      # integer_accessor :max_width, :min=>1
      string_accessor :label
      block_accessor :renderer
      enum_accessor :align, [:left, :right]

      def initialize(table,*args,&block)
        @table = table
        @visible = true
        Hipe::HashLikeWriteOnceExtension[opts = {}]
        opts.write_once!
        args.each do |arg|
          case arg
          when Symbol: opts[:name] = arg
          when Fixnum: opts[:min_width] = arg
          when Hash:   opts[:opts] = arg
          else
            raise TypeError.new("unrecognized type for field construction - #{arg.inspect}")
          end
        end
        if (opts[:opts])
          their_opts = opts.delete(:opts)
          if (dups = their_opts.keys & opts.keys).size > 0
            raise ArgumentError.new("The way your parameters were interpreted there were duplicates "<<
              "of #{dups.map{|x| x.inspect}*' and '}")
          end
          opts.merge! their_opts
        end
        raise ArgumentError.new("Fields must have names") unless opts[:name]
        raise TypeError.new("For now fields must have blocks (#{opts[:name]})") unless block
        set opts
        @renderer = block
      end
      def hide
        @visible = false
      end
      def show
        @visible = true
      end
      def label
        @label || @table.labelize.call(@name)
      end
      protected
      def set(hash)
        hash.each do |key,value|
          meth = %{#{key}=}
          unless respond_to? meth
            raise ArgumentError.new("unrecognized option #{key.inspect}") unless respond_to?(meth)
          end
          send(meth, value)
        end
      end
    end

    # this renders in two passes so it can set appropriate column widths for ascii\
    # probably not appropriate for html etc unless we are really lazy and performance isn't an issue
    class PreRenderingAsciiRenderer
      class << self
        extend Hipe::Loquacious::AttrAccessor
        symbol_accessor :renderer_name
      end
      self.renderer_name = :ascii
      Renderers.register_factory renderer_name, self
      extend Loquacious::AttrAccessor
      attr_reader :separator_at
      string_accessor :left
      string_accessor :right
      string_accessor :separator
      block_accessor :header
      block_accessor :top
      block_accessor :bottom
      block_accessor :after_header
      boolean_accessor :show_header
      kind_of_accessor :separator_at, Array

      # the default strategy for rendering horzontal lines will be ones that look like "+-------+"
      @lines = lambda{|w| %{+#{'-'*([w-2,0].max)}+} }

      class << self
        attr_reader :lines
      end

      def initialize
        @left         ||= '|  '
        @right        ||= ' |'
        @separator    ||= ' |  '
        @top          ||= self.class.lines
        @bottom       ||= self.class.lines
        @after_header ||= self.class.lines
        @show_header  = nil if @show_header.nil? # yes
        @separator_at ||= []
      end

      def render(table)
        return "(list is not set)" unless table.list
        # pre-render to calculate min_widths from actual values
        visible_fields = table.visible_fields
        show_header =
          if table.show_header.nil? && show_header?.nil? : true
          elsif show_header?.nil? : table.show_header
          else show_header? end

        min_widths = visible_fields.map{|field| show_header ? (field.min_width || field.label.length) : 0  }
        rows = []
        if (visible_fields.size > 1)
          separators_at = Array.new(visible_fields.size - 1, @separator)
          separator_at.each_with_index do |sep,idx|
            next if sep.nil?
            separators_at[idx] = sep
          end
        else
          separators_at = []
        end

        table.list.each do |item|
          row = []
          visible_fields.each_with_index do |field,index|
            # next unless field.visible?
            rendered = field.renderer.call(item).to_s
            min_widths[index] = rendered.length if rendered.length > min_widths[index]
            row << rendered
          end
          rows << row
        end

        table_width = @left.length + @right.length + min_widths.reduce(:+) +
          separators_at.map{|x| x.length}.reduce(:+)

        # render
        out = Hipe::Io::BufferString.new
        out.puts @top.call(table_width) if @top
        if show_header
          out << @left
          out << visible_fields.map do |field|
            min_width = field.min_width || min_widths[visible_fields.index(field)]
            str = sprintf(%{%#{min_width}s}, field.label)
            str
          end.zip(separators_at + ['']).flatten.join
          out.puts @right
        end
        if (show_header and @after_header)
          out.puts @after_header.call(table_width)
        end
        rows.each do |row|
          out << @left
          out << row.each_with_index do |cel, idx|
            field = visible_fields[idx]
            min_width = field.min_width || min_widths[idx]
            left = (field.align == :left) ? '-' : ''
            row[idx] = sprintf(%{%#{left}#{min_width}s},cel)
          end.zip(separators_at + ['']).flatten.join
          out.puts @right
        end
        out.puts @bottom.call(table_width) if @bottom
        out
      end
    end

    class PreRenderingHorizontalAsciiRenderer < PreRenderingAsciiRenderer
      self.renderer_name = :ascii_horizontal
      Renderers.register_factory renderer_name, self
      enum_accessor :value_cels_alignment, [:left, :right]

      def initialize
        @show_header ||= false
        @separator_at ||= [' = ']
        @value_cels_alignment ||= :left
        @left ||= ''
        @right ||= ''
        super
      end
      def render(table)
        return "(list is not set)" unless table.list
        visible_fields = table.visible_fields
        list = []
        visible_fields.each do |field|
          row = [field.label]
          table.list.each do |item|
            row << field.renderer.call(item).to_s
          end
          list << row
        end
        orig_renderer = self
        new_table = Hipe::Table.make do
          self.name = table.name
          self.show_header = table.show_header
          field(:property){|x| x[0]}
          table.list.each_with_index do |item,idx|
            field((idx + 1).to_s.to_sym, :align => (orig_renderer.value_cels_alignment||:right)){|x| x[idx+1]}
          end
          renderer(:ascii) do |r|
            [:left        ,
            :right        ,
            :separator    ,
            :top          ,
            :bottom       ,
            :after_header ,
            :show_header  ,
            :separator_at ].each { |x| r.send(%{#{x}=}, orig_renderer.send(%{#{x}})) }
          end
        end
        new_table.list = list
        new_table.render(:ascii)
      end
    end
  end
end
