# bacon spec/loquacious/spec_base.rb
# bacon spec/struct/spec_table.rb

require 'hipe-core'
require 'hipe-core/lingual/en'
require 'hipe-core/struct/open-struct-extended'

module Hipe

  module Loquacious

    # the idea here started out as just an abstract as possible validation library,
    # not tied too much to any framework.  It turned into a small reflection library, too
    # and got merged with StrictSetterGetter, and looks longingly over at Hipe::Interactive

    # right now the validation is built off of set theory (a very rudimentary subset of it)
    #
    # Currently the only public interface to anything in this file is @see Hipe::Loquacious::AttrAccessor

    class LoquaciousException < RuntimeError; end # for errors in using the library, not validation errors

    class OpenSetterException < ArgumentError; end

    module OpenSetter
      # if you call set() with a hash, will set all corresponding properties that have setters,
      # (defined either in your class or in parent classes.)
      # will raise ArgumentError else.  For now no respect for method privacy.
      # you also get setters() which returns an array of the valid setters names (w/o equals) as strings
      # this list will also go all the way up your inheritance chain

      include Hipe::Lingual::English
      def open_set opts
        raise OpenSetterException.new("open_set() needs Hash had #{opts.class}") unless opts.kind_of? Hash
        opts.each do |key,value|
          unless respond_to?( meth=%{#{key}=} )
            list = open_setters
            raise OpenSetterException.new %|Invalid option #{key.inspect} for #{self.class} -- | <<
              en{sp(np('available option',list))}.say
          end
          send meth, value
        end
      end
      def open_setters
        self.class.instance_methods(true).map{|x| (md = x.match %r{^(.*[a-z0-9_])=$}) ? md[1] : nil }.compact.sort
      end
    end


    ######################### the attr accessors and support ###########################


    module AttrAccessorImplementation
      # things in this module are supposed to be api protected.  The only reason someone
      # should need knowledge of in here is if they are making their own module of class methods (like setter getter makers)

      module InstanceMethods
        def handle_interaction_issues issues
          @interaction_issues ||= []
          @interaction_valid = false
          @interaction_issues.concat issues
          if on_interaction_issues.respond_to?(:call)
            return on_interaction_issues.call(issues)
          elsif :invalidate == on_interaction_issues
            # handled above
          elsif :throw == on_interaction_issues
            throw_this = @on_interaction_issues_throw || :issues
            throw throw_this, issues
          else
            raise issues.last.type.new issues.last.message
          end
        end
      end

      module ClassMethods
        def defined_accessors
          @defined_accessors ||= begin
            # we first used to just check ancestors[1] but forgot that includes modules
            # then we used to just check superclass but that infinite looped when there was an eigenclass
            ancestor = ancestors.slice(1,ancestors.size).detect{|y| y.class == Class && y.respond_to?(:defined_accessors) }
            if (ancestor)
              ancestor.defined_accessors.dup
            else
              {}
            end
          end
        end
      end

      module ClassMethodsPlusInstanceMethods
        def extend_object klass
          super
          klass.instance_eval do
            attr_accessor :on_interaction_issues # @todo in parent child when both extend AttrAccessor, check that ... no clobber
            include InstanceMethods
          end
        end
      end
    end

    # populated below
    module AttrAccessorDefaultMethodSet
      #
      # We are familiar with attr_accessor, a class method that generates instance methods
      # (i.e. "getters" and "setters").
      #
      # If your class includes this module, your class will get class methods that generate instance methods
      # that do some rudimentary validation, maybe duck-type assertion, maybe coercision.
      #
      # e.g.
      #   class Person
      #     extend Hipe::Loquacious::AttrAccessor
      #     string_accessor :first_name, :nil => true, :use => :to_str
      #     string_accessor :last_name, :use => :to_str
      #     boolean_accessor :is_admin
      #     integer_accessor :age, :min => 0, :max => 120
      #   end
      #
      # In the above example, the first name can be nil, the last name cannot.  Anything that has a to_str() method
      # can be used to set a first_name or a last_name.  When setting is_admin you can only use true or false.
      # When setting age you must use a Fixnum that is within the given range.
      #
      # If your class has setters and getters for booleans, a '?'-form alias for the getter will be created.
      # (In the above example, a person.is_admin? form would have been created.)
      #
      # Examples of available "types" are: callable, symbol, integer (with optional range assertion), and "boolean"
      #
      # Additionally, this will give your class a degree of reflection with the accessors() method,
      # which is a getter that reveals information about the setters of your class
      #
      #
      # for some "types" a :use flag can be used to recognize one coercion method on parameters,
      # eg. string_attr_accessor :name, :use => :to_str (this is not yet implemented fully)
      #
      # For example, if your class needs to be able to make setters and getters for proc instance variables,
      #
      #   class MyClass
      #     extend Hipe::Loquacious::AttrAccessor
      #     block_attr_accessor :row_filter, :field_filter
      #   end
      #
      #   obj = MyClass.new
      #   obj.row_filter{|x| ... }              # now @row_filter is set to that Proc
      #   obj.row_filter = 'not a proc'         # this will throw an ArgumentError
      #   obj.field_filter = obj.row_filter     # this shows getting procs, and a different way to set them
      #

      include AttrAccessorImplementation::ClassMethods
      extend AttrAccessorImplementation::ClassMethodsPlusInstanceMethods
    end

    AttrAccessor = AttrAccessorDefaultMethodSet

    class StrictAttrAccessor
      # base-class for every setter-getter-maker in this library.
      # for now they are immutable and stateless
      include OpenSetter
      attr_reader :name, :opts, :block
      def initialize name, opts=nil
        raise LoquaciousException.new(
          "For now, symbols only, not #{name.inspect} for foo_accessor names") unless name.kind_of? Symbol
        @name = name.freeze
        open_set opts if opts
        @opts = opts # even though the above may set member variables
        # we will use only this property to detect equality
      end
      def == o
        o.is_a?(self.class) && @name == o.name && @opts == o.opts && @block == o.block
      end
      alias_method :eql?, :== # for Set and Hash
      def hash
        @name.hash
        #{}%{#{@name.hash}-#{@opts.hash}-#{@block.hash}}.hash
      end
      def self.add_attr_accessor_constructor mojule, constructor_name, plural_form = nil
        attr_accessor_class = self
        mojule.module_eval do
          define_method(constructor_name) do |*args, &block|
            accessor = attr_accessor_class.new(*args, &block)
            accessor.define_accessor_methods_on self
            defined_accessors[accessor.name] = accessor
          end
          if plural_form
            define_method(plural_form) do |*args|
              args.each do |arg|
                send constructor_name, arg
              end
            end
          end
        end
      end
      def include? mixed
        @set.include? mixed
      end
      def issues_with mixed
        @set.issues_with mixed
      end
      def define_writer_method_on(klass)
        writer = self
        name = self.name
        klass.module_eval do
          define_method(%{#{name}=}) do |mixed|
            mixed = writer.preprocess_value(mixed) if writer.respond_to?(:preprocess_value) # usu. just for coercion
            if writer.include? mixed
              instance_variable_set %{@#{name}}, mixed
            else
              issues = writer.issues_with(mixed)
              issues.each do |issue|
                issue.property_name = name
                issue.provided_value = mixed
              end
              handle_interaction_issues issues
              return issues # experimental!
            end
          end
        end
      end
      def define_accessor_methods_on(klass)
        name = self.name
        klass.module_eval do
          define_method(name){ instance_variable_get(%{@#{name}}) }
        end
        define_writer_method_on klass
      end
    end

    class Issue < OpenStructExtended # Struct.new(:property_name, :message, :type, :exception_class)
      # rather than call them errors (an error is in the eye of the beholder)
      # or exceptions (raise() has been coralled into one place) we go for a softer, less presumtuous term
      def message
        data = @table.dup
        data[:provided_value] = @table[:provided_value].inspect
        data[:property_name] ||= 'value'
        self.message_template_en.gsub(/#\{([a-z_]+)\}/){|x| data[$1.to_sym] }
      end
      def type
        @table[:type]
      end
    end


    ################## can-foo modules #####################################
    # These are for setter getter makers to use to enable options that are common
    # to several setter getter makers, options like :min, :max, :use, :nil

    module CanCoerceWith
      def self.included klass
        klass.send :attr_accessor, :use
      end
      def preprocess_value mixed
        (@use && mixed.respond_to?(@use)) ? mixed.send(@use) : mixed
      end
    end

    module CanMinMax
      def self.included klass
        klass.send :attr_reader, :min, :max
      end
      def min= min
        @range ||= PartialRangeSet.new(nil,nil)
        @range.begin = min
      end
      def max= max
        @range ||= PartialRangeSet.new(nil,nil)
        @range.end = max
      end
    end

    module CanNil
      def self.included klass
        klass.send :attr_accessor, :nil
      end
    end

    ######################### the attr accessors #################################

    DefaultAttrAccessors = {}
    class BlockAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :block_accessor, :block_accessors
      def initialize *args
        super
      end
      def define_accessor_methods_on klass
        name = self.name
        klass.class_eval do
          define_method(%{#{name}=}) do |block|
            instance_variable_set %{@#{name}}, block
          end
          define_method(name) do |&block|
            if block.nil?
              instance_variable_get %{@#{name}}
            else
              instance_variable_set %{@#{name}}, block
            end
          end
        end
      end
    end

    class BooleanAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :boolean_accessor, :boolean_accessors
      include CanNil
      def initialize name, opts={}
        super
        enum = [true, false]
        enum << nil if @nil
        @set = PrimitiveEnumSet.new(*enum )
      end
      def define_accessor_methods_on klass
        super
        klass.send(:alias_method, %{#{name}?}, name)
      end
    end

    class EnumAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :enum_accessor
      include CanNil
      include CanCoerceWith
      attr_accessor :enum
      def initialize name, array, opts={}
        array << nil if opts[:nil] and ! array.include? nil
        opts[:enum] = array
        super(name, opts)
        @set = PrimitiveEnumSet.new(*opts[:enum])
      end
    end

    class IntegerAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :integer_accessor, :integer_accessors
      include CanMinMax
      include CanCoerceWith
      include CanNil
      def initialize *args
        super
        unions = []
        unions << PrimitiveEnumSet.new(nil) if @nil
        intersects = [KindOfSet.new(Fixnum)]
        intersects << @range if @range
        unions << ( intersects.size > 1 ? IntersectedSet.new(*intersects) : intersects[0] )
        @set = unions.size > 1 ? UnionedSet.new(*unions) : unions[0]
      end
    end

    class KindOfAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :kind_of_accessor
      attr_accessor :module
      include CanNil
      def initialize name, mojule
        opts = {:module => mojule}
        super name, opts
        unions = [KindOfSet.new(mojule)]
        unions << PrimitiveEnumSet(nil) if @nil
        @set = unions.size > 1 ? UnionedSet.new(*unions) : unions[0]
      end
    end

    class StringAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :string_accessor, :string_accessors
      include CanCoerceWith
      include CanNil
      attr_accessor :regexp
      def initialize *args
        super
        unions = []
        unions << PrimitiveEnumSet.new(nil) if @nil
        intersects = [KindOfSet.new(String)]
        intersects << RegexpSet.new(@regexp) if @regexp
        unions << ( intersects.size > 1 ? IntersectedSet.new(*intersects) : intersects[0] )
        @set = unions.size > 1 ? UnionedSet.new(*unions) : unions[0]
      end
    end

    class SymbolAttrAccessor < StrictAttrAccessor
      add_attr_accessor_constructor AttrAccessorDefaultMethodSet, :symbol_accessor, :symbol_accessors
      include CanCoerceWith
      include CanNil
      def initialize name,*args
        super
        unions = [KindOfSet.new(Symbol)]
        unions << PrimitiveEnumSet.new(nil) if @nil
        @set = unions.size > 1 ? UnionedSet.new(*unions) : unions[0]
      end
    end

    ###################### Set-related validators and their exceptions ###################

    class ValidationException < ArgumentError; end

    class ValidatingSet
      include Hipe::Lingual::English

    end

    class SetSet < ValidatingSet
      def << set
        @sets << set
      end
    end

    class UnionedSet < SetSet
      # this used to be called OrSet.  It is like a chain of boolean statements joined together with "or"

      def initialize *sets
        @sets = sets
      end
      def include? mixed
        @sets.each do |set|
          return true if set.include? mixed
        end
        false
      end
      def issues_with mixed
        @sets.map{ |set| set.issues_with mixed }.flatten
      end
    end

    class EnumValidationException < ValidationException; end

    class PrimitiveEnumSet < UnionedSet
      def initialize *values
        @values = values
      end
      def include? mixed
        @values.include? mixed
      end
      def issues_with mixed
        return [] if @values.include? mixed
        list = @values
        [Issue.new(
          :message_template_en => %q|#{provided_value} is a invalid value for #{property_name}. | <<
            en{sp(np('valid value',list))}.say.capitalize,
          :valid_values => @values,
          :type => EnumValidationException
        )]
      end
    end

    class IntersectedSet < SetSet
      # this is a short-circuiting form.  if we need one we can make a long-circuiting form
      # this used to be called AndSet.  It is like a chain of boolean statements joined together with "and"

      def initialize *args
        @sets = args
      end
      def include? mixed
        @sets.map{ |set| set.include? mixed }.select{ |x| x }.count == @sets.count
      end
      def issues_with mixed
        @sets.each{ |set| issues = set.issues_with mixed; return issues if issues.size > 0 }
        []
      end
    end

    module RangeLike
      def self.enhance range
        throw LoquaciousException.new("need range had #{range.inspect}") unless
          range.respond_to?(:begin) and range.respond_to?(:end)
        range.extend RangeLike
        range
      end

      def excludes?(value)
        if self === value # Range class implement this
          false
        else
          if value < self.end
            %{below the minimum of #{self.begin}}
          else
            %{above the maximum of #{self.end}}
          end
        end
      end
    end

    class Range < ::Range
      include RangeLike
    end

    class RangeValidationException < ValidationException; end

    class PartialRangeSet < ValidatingSet
      # include RangeLike
      attr_accessor :begin, :end

      def initialize min, max, exclusive=false
        @begin, @end, @exclusive = min, max, exclusive
      end

      def === mixed
        if @exclusive
          ! ((@begin && mixed <  @begin) || (@end && mixed > @end ))
        else
          ! ((@begin && mixed <= @begin) || (@end && mixed >= @end ))
       end
      end

      def include? mixed
        self === mixed
      end

      def issues_with mixed
        verb_phrase =
         if @exclusive
            if (@begin && mixed <= @begin)
              below = true
              "must be greater than #{@begin}"
            elsif (@end && mixed >= @end)
              below = false
              "must be less than #{@end}"
            end
          else
            if (@begin && mixed < @begin)
              below = true
              "can't be below #{@begin}"
            elsif (@end && mixed > @end)
              below = false
              "can't be above #{@end}"
            end
          end
        return [] unless verb_phrase
        [Issue.new(
          :message_template_en => %q|#{provided_value} | << verb_phrase,
          :type => RangeValidationException,
          :below_or_above => below ? :below : :above,
          :min => @begin,
          :max => @end,
          :exclusive => @exclusive
        )]
      end
    end

    class RegexpValidationException < ValidationException; end

    class RegexpSet < ValidatingSet

      def initialize re, message_template_en = nil
        @message_template_en ||= %q|#{provided_value} did not match the expected pattern|
        @re = re
      end

      def include? mixed
        @re =~ mixed
      end

      def issues_with mixed
        return [] if @re =~ mixed
        [Issue.new( :message_template_en => @message_template_en, :type => RegexpValidationException)]
      end
    end

    class KindOfValidationException < ValidationException; end

    class KindOfSet < ValidatingSet

      def initialize mojule, message_template_en = nil
        @message_template_en = message_template_en ||
          %{needed \#{property_name} to be #{mojule}, was \#{provided_value}}
        @mojule = mojule
      end

      def include? mixed
        mixed.kind_of? @mojule
      end

      def issues_with mixed
        return [] if include? mixed
        [Issue.new( :message_template_en => @message_template_en, :type => KindOfValidationException)]
      end
    end
  end
end
