##
# A class that includes Interfacey::Service will have an Interface,
# which provides a set of Abilities.
# (each Ability will usually correspond to an instance method in the
# implementation)
# Each ability has its own Request class, which is a struct.
# Each object of a Service has its own Interface object, which is duped from
# the defined ("prototype") Interface defined in the class.
# An Ability of an interface can be hidden or shown.


# "these are not within the parameters of my ability"
require 'ruby-debug'

module Hipe
  module Interfacey
    module Exception; end
    class ArgumentError < ::ArgumentError
      include Exception
    end
    module Service
      def self.included mod
        class << mod
          attr_accessor :interface
        end
        mod.interface = Interface.new
      end
    end
    # OrderedHash can be annoying
    class AssociativeArray < Array
      # if we need these we will have to deal with @keys and @keys_order
      undef :delete, :delete_at, :pop, :reject!, :replace, :shift, :slice!
      def initialize
        super
        @clobber = true
        @keys = {}
        @keys_order = []
      end
      alias_method :orig_store, :[]=
      alias_method :orig_fetch, :[]
      def []=(key, thing)
        if (!@clobber && (key.class==Fixnum) ?
          (i < length) : @keys.has_key?(key))
          raise ArgumentError.new("Won't clobber #{key.inspect}")
        end
        super if key.class == Fixnum
        index = length;
        orig_store index, thing
        @keys_order.push(key) unless @keys[key]
        @keys[key] = index
      end
      def [](key)
        orig_fetch(key) if key.class == Fixnum
        orig_fetch @keys[key]
      end
      def keys
        @keys_order.dup
      end
      def no_clobber
        @clobber = false
      end
    end
    module Switch
      def unparse
        '['+[ (@short[0] && "-#{@short[0]}") || (@long[0] && "--#{@long[0]}"),
        takes_argument? ? argument_required? ? "<#{@argument_name}>" :
          "[#{@argument_name}]" : nil ].compact * ' ' + ']'
      end
      alias_method :inspect, :unparse
    end
    class ParameterDefinition
      CliSwitchRe = %r{ [[:space:]]*
        \[-
          (?:
            ([a-z])
            |
            -(?:
              ([a-z0-9][-a-z0-9]+)
              |
              ([a-z0-9]*[-a-z0-9]*)\[([a-z0-9])\]([-a-z0-9]*)
            )
          )
          (?:
            (?:[[:space:]]|=)
            <([a-z_]+)>
            |
            [[:space:]]*
            \[
              (?:[[:space:]]|=)
              <([a-z_]+)>
            \]
          )?
        \]
        [[:space:]]*
      }x
      def self.[](md, type)
        ParameterDefinition.new(md, type)
      end
      attr_reader :short, :long, :argument_name, :argument_required,
        :parameter_required
      alias_method :argument_required?, :argument_required
      alias_method :parameter_required?, :parameter_required
      def initialize  md, type
        case type
        when :switch
          extend Switch
          @cli_type = :switch
          @parameter_required = false
          @short = [md[1] || md[4]]
          @long = [md[2] || "#{md[3]}#{md[4]}#{md[5]}"]
          @argument_name = md[6] || md[7]
          if @argument_name
            @argument_required = ! md[7]
          end
          @short.compact!
          @long.reject!{|x| x==""}
        end
      end
      def takes_argument?
        !! @argument_name
      end
      def name
        @long.length > 0 ? @long[0] : @short[0]
      end
    end
    class Abilities < AssociativeArray; end
    class Ability
      NameRe = %r|^([[:space:]]*[a-z][-a-z0-9_]+[[:space:]]*)(.*)$|
      def self.[](*args)
        case args.size
        when 1
          case args[0]
          when String
            return from_string args[0]
          else
            raise ArgumentError.new(
              "invalid kind_of for Ability definition: #{args[0].inspect}")
          end
        else
          raise ArgumentError.new("Expecting 1 had #{args.size}")
        end
      end
      def self.from_string string
        p = DefinitionParse.new
        def_struct = p.parse string
        return new(def_struct.name, def_struct.parameters)
      end

      attr_reader :name, :parameters
      def initialize name, parameter_definitions
        @name = name
        @parameters = parameter_definitions
      end
      class AbilityDefinitionParseTree < Struct.new(:name, :parameters); end
      class DefinitionParse
        def initialize
          @offset = 0
        end
        class Error < ArgumentError
          def initialize msg
            @message = msg
          end
          def context(original_string, offset)
            @original_string = original_string
            @offset = offset
          end
          # show local excerpt if possible
          def to_s
            md = nil
            return @message unless @original_string && @offset
            re = %r|^(.{#{@offset}})([[:space:]]*)([^[:space:]]+)|m
            return @message if (!md=re.match(@original_string))
            before_offset, leading_spaces, line_tail = md.captures
            re = %r|([^[:space:]]*[[:space:]]*)\Z|m
            return @message if (!md=re.match(before_offset))
            line_head = md[1]
            return sprintf("%s at:\n%s\n%s", @message,
            "#{line_head}#{line_tail}",'-' * [0,line_head.length-1].max + '^')
          end
        end
        def parse string
          eat_me = string.dup
          orig_string = string.dup
          begin
            parameters = AssociativeArray.new
            parameters.no_clobber
            name = nil
            catch :end_of_string do
              name = parse_off_name eat_me
              parse_off_switches eat_me, parameters
              parse_off_required eat_me, parameters
              parse_off_optional eat_me, parameters
              parse_off_splat eat_me, parameters
            end
            return AbilityDefinitionParseTree.new(name, parameters)
          rescue Error => e
            e.context(orig_string, @offset)
            raise e
          end
        end
        def parse_off_name string
          md = NameRe.match(string)
          raise Error.new("expecting valid name") unless md
          @offset += md[1].length
          string.slice!(0,md[1].length)
          md[1].strip
        end
        def parse_off_switches string, assoc_array
          while (md = ParameterDefinition::CliSwitchRe.match(string))
            parameter = ParameterDefinition[md, :switch]
            assoc_array[parameter.name] = parameter
            @offset += md[0].length
            string.slice!(0,md[0].length)
          end
          throw :end_of_string if ""==string
        end
        def parse_off_required string, assoc_array
          while (md = ParameterDefinition::CliRequiredRe.match(string))
            parameter = ParameterDefinition[md, :switch]
            assoc_array[parameter.name] = parameter
            @offset += md[0].length
            string.slice!(0,md[0].length)
            throw :end_of_string if (""==string)
          end
        end
        def parse_off_optional string, assoc_array
          while (md = ParameterDefinition::CliRequiredRe.match(string))
            string.slice!(0,md[0].length)
            parameter = ParameterDefinition[md, :switch]
            assoc_array[parameter.name] = parameter
            @offset += md[0].length
          end
        end
      end
    end
    class Interface
      attr_reader :abilities
      def initialize
        @abilities = Abilities.new
      end
      def responds_to *args
        ability = Ability[*args]
        puts "ok"
      end
    end
  end
end
