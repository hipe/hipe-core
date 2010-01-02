# bacon spec/infrastructure/spec_strict-setter-getter.rb
# bacon spec/struct/spec_table.rb
require 'hipe-core'
require 'hipe-core/loquacious/all'
require 'set'
module Hipe
  module StrictSetterGetter

    # Like attr_accessor, this creates setters and getters on your class but unlike attr_accessor
    # this enforces type (kind of), follows some syntactic conventions and maybe does some validations
    # and allows for some reflection with setter_getters
    #
    # Available "types" are: callable, symbol, integer (with optional range assertion), and "boolean"
    #
    #
    # For example, if your class needs to be able to make setters and getters for proc instance variables,
    #
    #   class MyClass
    #     extend Hipe::StrictSetterGetter
    #     block_setter_getters :row_filter, :field_filter
    #   end
    #
    #   obj = MyClass.new
    #   obj.row_filter{|x| ... }              # now @row_filter is set to that Proc
    #   obj.row_filter = 'not a proc'         # this will throw a TypeError
    #   obj.field_filter = obj.row_filter     # this shows getting procs, and a different way to set them
    #
    #
    # If your class has setters and getters for booleans, a '?'-form alias for the getter will be created
    #

    # just for reflection api
    class SetterGetter
      attr_reader :name, :args, :block
      def initialize name, *args, &block
        @name = name
        @args = args
        @block = block
        freeze
      end
      def == o
        o.is_a?(self.class) && @name == o.name && @args == o.args && @block == o.block
      end
      alias_method :eql?, :==
      # for Set
      def hash
        %{#{@name.hash}-#{@args.hash}-#{@block.hash}}.hash
      end
    end

    class BooleanSetterGetter    < SetterGetter; end
    class StringSetterGetter     < SetterGetter; end
    class SymbolSetterGetter     < SetterGetter; end
    class IntegerSetterGetter    < SetterGetter; end
    class KindOfSetterGetter     < SetterGetter; end
    class KindOfEachSetterGetter < SetterGetter; end
    class BlockSetterGetter      < SetterGetter; end

    SymbolOptions = {
      :enum => lambda do |klass, property, enum_list, validations|
        Hipe::Loquacious::EnumLike[enum_list]
        klass.instance_variable_set(%{@#{property}_enum}, enum_list)
        meta = class << klass; self end
        meta.send(:define_method,%{#{property}_enum}){ instance_variable_get(%{@#{property}_enum}) }
        validations << lambda do |value, object|
          enum_list = object.class.send(%{#{property}_enum})
          if (err_msg = enum_list.excludes?(value)) then raise ArgumentError.new(err_msg) end
        end
      end
    }

    def self.extended(klass)
      klass.send :instance_variable_set, '@strict_setter_getters', Set.new

      class << klass

        def strict_setter_getters;
          @strict_setter_getters ||= begin
            ancestors[1].strict_setter_getters.dup
          end
        end

        # Creates a setter getter that takes a block argument as its parameter
        # Asserts that the argument responds to :send
        def block_setter_getters *args
          args.each do |name|
            define_method(%{#{name}=}) do |val|
              raise TypeError.new("#{name} must be a callable, not #{val.inspect}") unless val.respond_to?(:send)
              instance_variable_set(%{@#{name}}, val)
            end
            define_method(name) do |&block|
              block.nil? ? instance_variable_get(%{@#{name}}) : send(%{#{name}=}, block)
            end
            strict_setter_getters.add BlockSetterGetter.new(name, *args)
          end
        end
        alias_method :block_setter_getter, :block_setter_getters

        # This is not expected to be used very often.  Like kind_of_setter_getter, but takes a list and
        # asserts that the thing is a kind_of? each item on the list
        # The only reason this is here is because this used to be the implementation for kind_of when it takes a list
        def kind_of_each_setter_getter name, arg, *args
          args.unshift(arg)
          validations = args.map do |mojule|
            validator = Loquacious::KindOf.new mojule
            lambda do |value|
              if (msg = validator.excludes?(value)) then raise TypeError.new(msg) end
            end
          end
          define_method(%{#{name}=}) do |val|
            validations.each{ |validation| validation.call(val) }
            instance_variable_set(%{@#{name}}, val)
          end
          attr_reader name
          strict_setter_getters.add KindOfEachSetterGetter.new(name, *args)
        end

        # Creates a setter getter that asserts that the value is a kind_of? at least one of the items in the list
        def kind_of_setter_getter name, arg, *args
          args.unshift(arg)
          loquacii = {}
          args.each do |mojule|
            loquacii[mojule] = Loquacious::KindOf.new mojule
          end
          validations = [lambda do |value|
            unless (success = loquacii.detect{|x| value.kind_of?(x[0])})
              raise TypeError.new(Loquacious::EnumLike[args].say(value.class))
            end
          end]
          define_method(%{#{name}=}) do |value|
            validations.each{ |validation| validation.call(value) }
            instance_variable_set(%{@#{name}}, value)
          end
          attr_reader name
          strict_setter_getters.add KindOfSetterGetter.new(name, *args)
        end

        def boolean_setter_getters *args
          args.each do |name|
            define_method(%{#{name}=}) do |val|
              raise TypeError.new("#{name} must be a Boolean, not #{val.inspect}") unless
                [TrueClass,FalseClass].include?(val.class)
              instance_variable_set(%{@#{name}}, val)
            end
            attr_reader name
            alias_method %{#{name}?}, name
            strict_setter_getters.add BooleanSetterGetter.new(name, [], nil)
          end
        end
        alias_method :boolean_setter_getter, :boolean_setter_getters


        def integer_setter_getter name, *args, &block
          validations = []
          validations << block if block
          args.each do |arg|
            case arg
            when Range
              range = Loquacious::Range[arg.dup]
              validations << lambda do |x|
                if (msg=range.excludes?(x)) then raise ArgumentError.new(%{#{name} was #{msg}}) end
              end
            when Hash
              wierd = arg.keys - [:min, :max]
              raise ArgumentError.new("expecting min/max had #{wierd.map{|x|x.inspect}*' and '}") if wierd.size > 0
              range = Loquacious::PartialRange.new(arg[:min], arg[:max])
              validations << lambda do |x|
                if (msg=range.excludes?(x)) then raise ArgumentError.new(%{#{name} was #{msg}}) end
              end
            else
              raise TypeError.new("expecting Range had #{arg.type}")
            end
          end
          define_method(%{#{name}=}) do |val|
            raise TypeError.new("#{name} must be a Fixnum, not #{val.inspect}") unless val.kind_of? Fixnum
            validations.each{ |validation| validation.call(val) }
            instance_variable_set(%{@#{name}}, val)
          end
          attr_reader name
          strict_setter_getters.add IntegerSetterGetter.new(name, *args, &block)
        end


        def string_setter_getter name, *args, &block
          validations = []
          validations << block if block
          args.each do |arg|
            case arg
            when Regexp
              raise "implement me"
              range = Loquacious::Regexp[arg]
              validations << lambda do |x|
                if (msg=range.excludes?(x)) then raise ArgumentError.new(%{#{name} was #{msg}}) end
              end
            else
              raise TypeError.new("expecting Regexp had #{arg.type}")
            end
          end
          define_method(%{#{name}=}) do |val|
            raise TypeError.new("#{name} must be a String, not #{val.inspect}") unless val.kind_of? String
            validations.each{ |validation| validation.call(val) }
            instance_variable_set(%{@#{name}}, val)
          end
          attr_reader name
          strict_setter_getters.add StringSetterGetter.new(name, *args, &block)
        end
        def string_setter_getters *args
          args.each do |arg|
            string_setter_getter(arg)
          end
        end


        def symbol_setter_getter name, *args, &block
          validations = []
          validations << block if block
          args.each do |arg|
            case arg
            when Hash
              arg.each do |opt_name, opt_value|
                raise ArgumentError.new("invalid option #{opt_name.inspect}") unless SymbolOptions[opt_name]
                SymbolOptions[opt_name].call(self,name,opt_value,validations)
              end
            else
              raise TypeError.new("expecting Hash had #{arg.type}")
            end
          end
          define_method(%{#{name}=}) do |val|
            raise TypeError.new("#{name} must be a Symbol, not #{val.inspect}") unless val.kind_of? Symbol
            validations.each{ |validation| validation.call(val,self) }
            instance_variable_set(%{@#{name}}, val)
          end
          attr_reader name
          strict_setter_getters.add SymbolSetterGetter.new(name, *args, &block) if strict_setter_getters
        end
        def symbol_setter_getters *args
          args.each do |name|
            symbol_setter_getter name
          end
        end
      end
    end
  end
end
