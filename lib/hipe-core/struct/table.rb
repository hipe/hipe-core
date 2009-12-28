require 'hipe-core'
require 'hipe-core/infrastructure/strict-setter-getter'
require 'hipe-core/io/buffer-string'
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

    extend StrictSetterGetter

    protected
      def initialize
        @fields = []
        @fields_by_name = {}
        @renderers = {}
        @show_header = true
      end

      def self.humanize_lite(str)
        str.to_s.gsub('_',' ')
      end

    public
    attr_accessor :fields
    attr_reader :list
    block_setter_getter :labelize
    boolean_setter_getters :visible, :show_header

    def self.make &block
      t = self.new
      t.instance_eval(&block)
      t.labelize ||= lambda{ |field_name| humanize_lite(field_name) }
      t
    end

    def field(*args,&block)
      if block
        f = Field.new(self,*args,&block)
        raise ArgumentError.new("Can't redefine field: #{f.name.inspect}") if @fields_by_name[f.name]
        @fields << f
        @fields_by_name[f.name] = f
      else
        raise ArgumentError.new("use field() either to define a field or access one") unless args.size == 0
        @fields_by_name
      end
    end

    def list=list
      raise TypeError.new("list must be enumerable") unless list.kind_of? Enumerable
      @list = list
    end

    def renderer(name,&block)
      if (block)
        renderer = (@renderers[name] ||= PreRenderingAsciiRenderer.new)
        block.call(renderer)
        renderer.set_defaults
        nil
      else
        unless (@renderers.has_key? name)
          @renderers[name] = case name
          when :ascii then PreRenderingAsciiRenderer.new
          else raise ArgumentError.new("There is no set renderer for #{name.inspect}");
          end
          @renderers[name].set_defaults
        end
        @renderers[name]
      end
    end

    def render(renderer_name)
      renderer(renderer_name).render(self)
    end

    class Field
      extend StrictSetterGetter
      symbol_setter_getter :name
      boolean_setter_getter :visible
      integer_setter_getter :min_width, :min=>1
      # integer_setter_getter :max_width, :min=>1
      string_setter_getter :label
      block_setter_getter :renderer

      def initialize(table,*args,&block)
        @table = table
        @visible = true
        opts = {}
        args.each do |arg|
          case arg
          when Symbol:
            raise ArgumentError.new("can only have one Symbol in args") if opts[:name]
            opts[:name] = arg
          when Fixnum:
            raise ArgumentError.new("can only have one Fixnum in args") if opts[:min_width]
            opts[:min_width] = arg
          when Hash:
            raise ArgumentError.new("can only have one Hash in args") if opts[:opts]
            opts[:opts] = arg
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
      extend StrictSetterGetter
      string_setter_getters :left, :right, :separator
      block_setter_getters :header, :top, :bottom, :after_header
      @lines = lambda{|w| %{+#{'-'*([w-2,0].max)}+} }
      class << self
        attr_reader :lines
      end
      def set_defaults
        @left         ||= '|  '
        @right        ||= ' |'
        @separator    ||= ' |  '
        @top          ||= self.class.lines
        @bottom       ||= self.class.lines
        @after_header ||= self.class.lines
      end
      def render(table)
        # pre-render to calculate min_widths from actual values
        show_fields = table.fields.select{|f| f.visible? }
        min_widths = show_fields.map{|field| table.show_header ? (field.min_width || field.label.length) : 0  }
        rows = []
        table.list.each do |item|
          row = []
          show_fields.each_with_index do |field,index|
            next unless field.visible?
            rendered = field.renderer.call(item)
            min_widths[index] = rendered.length if rendered.length > min_widths[index]
            row << rendered
          end
          rows << row
        end
        table_width = @left.length + @right.length + min_widths.reduce(:+) +
          ([show_fields.size-1,0].max * @separator.length)

        # render
        out = Hipe::Io::BufferString.new
        out.puts @top.call(table_width) if @top
        if table.show_header?
          out << @left
          out << show_fields.map do |field|
            min_width = field.min_width || min_widths[show_fields.index(field)]
            str = sprintf(%{%#{min_width}s}, field.label)
            str
          end.join(@separator)
          out.puts @right
        end
        if (table.show_header? and @after_header)
          out.puts @after_header.call(table_width)
        end
        rows.each do |row|
          out << @left
          out << row.each_with_index do |cel, idx|
            min_width = show_fields[idx].min_width || min_widths[idx]
            row[idx] = sprintf(%{%#{min_width}s},cel)
          end.join(@separator)
          out.puts @right
        end
        out.puts @bottom.call(table_width) if @bottom
        out
      end
    end
  end
end
