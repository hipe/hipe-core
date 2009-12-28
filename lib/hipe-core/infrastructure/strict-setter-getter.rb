require 'hipe-core'
require 'hipe-core/loquacious/all'
module Hipe
  module StrictSetterGetter  # waiting for a new home

    # Like attr_accessor, this creates setters and getters on your class but unlike attr_accessor
    # this enforces type (kind of), follows some syntactic conventions and maybe does some validations
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

    def self.extended(klass)
      class << klass
        def block_setter_getters *args
          args.each do |name|
            define_method(%{#{name}=}) do |val|
              raise TypeError.new("#{name} must be a callable, not #{val.inspect}") unless val.respond_to?(:send)
              instance_variable_set(%{@#{name}}, val)
            end
            define_method(name) do |&block|
              block.nil? ? instance_variable_get(%{@#{name}}) : send(%{#{name}=}, block)
            end
          end
        end
        alias_method :block_setter_getter, :block_setter_getters
        def symbol_setter_getters *args
          args.each do |name|
            define_method(%{#{name}=}) do |val|
              raise TypeError.new("#{name} must be a Symbol, not #{val.inspect}") unless val.kind_of? Symbol
              instance_variable_set(%{@#{name}}, val)
            end
            attr_reader name
          end
        end
        alias_method :symbol_setter_getter, :symbol_setter_getters
        def boolean_setter_getters *args
          args.each do |name|
            define_method(%{#{name}=}) do |val|
              raise TypeError.new("#{name} must be a Boolean, not #{val.inspect}") unless
                [TrueClass,FalseClass].include?(val.class)
              instance_variable_set(%{@#{name}}, val)
            end
            attr_reader name
            alias_method %{#{name}?}, name
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
        end
        def string_setter_getters *args
          args.each do |arg|
            string_setter_getter(arg)
          end
        end
      end
    end
  end
end
