##
# A class that includes Interfacey::Service will have an Interface.
# An Interface can speak zero or more of: :rack, :cli, [:gorilla_grammar ?]
# An Interface provides set (and list?) of Abilities.
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
    class ArgumentError < ::ArgumentError; include Exception end
    module Service
      def self.included mod
        class << mod
          attr_accessor :interface
        end
        mod.interface = Interface.new
      end
    end
    class ParameterDefinition
      attr_reader :required
      alias_method :required?, :required
    end
    # @todo - move to struct if you want to use it elsewhere, but
    # why should you? you will always want to use Interfacey too.
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
    class Abilities < AssociativeArray; end
    class Ability
      NameRe = %r|^([[:space:]]*[a-z][-a-z0-9_]+[[:space:]]*)(.*)$|
      attr_reader :name, :parameters
      def self.[](*args)
        if (args.size == 1 && args[0].kind_of?(String))
          return from_string args[0]
        end
      end
      def initialize name, parameter_definitions
        @name = name
        @parameters = parameter_definitions
      end
    end
    class Interface
      attr_reader :abilities
      def initialize
        @abilities = Abilities.new
      end
      def speaks context
        case context
        when :cli
          require 'hipe-core/interfacey/optparse-bridge'
        else
          raise ArgumentError.new("can't speak #{context.inspect}")
        end
      end
      def responds_to *args
        ability = Ability[*args]
        @abilities[ability.name] = ability
      end
    end
  end
end
