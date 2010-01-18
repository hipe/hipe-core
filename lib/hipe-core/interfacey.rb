##
# A class that includes Interfacey::Service will have one
# Intefacey::Interface. An Interface models the set
# (and list?) of (at times) "public" procedures
# the service reveals, called Abilities.
#
# A set of Abilities defines the set of requests (Requests?) that the
# implementing class can respond_to through its Interface.
# (We are using "set" and "list" here on purpose;) )
#
# An Ability has a name (string not symbol), and a set (list?) of zero
# or more ParameterDefinition s. (Not called "Parameters" to avoid confusion
# with the parameters of an individual request.)
#
# Each Ability will usually (always?) correspond to an instance method in the
# implementing class. (We considered calling this "Command" instead of
# "Ability" but we wanted to sound more positive about the whole thing, and to
# differentiate the processing of an individual request from the abstract
# definition of an operation.)
#
# Each object of a class that is a kind of Intefacey::Service
# could get its own Interface object,
# which could be duped from the defined ("prototype")
# Interface defined in the class, which would allow objects to change
# the state of their inteface throughout their lifecycle, for example
# hiding or showing certain Abilities, or hiding or alterting certain
# parameter definitions of an ability, based on object state or application
# context, (depending for example on the credentials of an authenticated
# user.)
#
# For now, an Interface can speak() zero or more of: :cli,
#  (:rack?) (:gorilla_grammar?) (:ruby?)
# These "paradigms" that an Inteface "speaks"
# may affect how its Abilities can be defined.  (For example, a cli command
# definition needs some different information than a rack command does because
# it's more syntagmatic and less structural, more array and less hash,
# more stream and less tree.).
#
# (A paradigm like :ruby already has a framework (language, if you will) for
# defining operations and their parameters, but something like this could
# add more reflection and validation capabilities to existing intefaces, if
# desired.
#
# Despite the differencs of these "paradigms", the overarching goal of this
# library is to enable as much cross-purpose command-processing as possible,
# and to provide a means to define commands (abilities) and to
# reflect on those abilities in a way that is abstract enough to ignore
# the details of the specific "paradigm".  For example, there is
# is significant crossover between the set of all command-line-like
# command definitions and the set of all rack-like command defintions.
# Any command-line command that doesn't use the splat parameter globber
# (and even those that do) can be repurposed to respond to rack requests in a
# regular way.  Any rack-like request can be repurposed to be processed by a
# cli-command if you tell it how the parameters of the request map to
# positional arguments of a cli command.
#
# Munging cli and web might feel .. mungey.. but note that both
# simply respond to requests, which from the application layer perspective
# start out as structures of strings when dealing with basic POST and GET
# requests.  Dealing with file upload can have lots of crossover with
# dealing with processing a file on the local system via command line.
#
# Another goal of this thing is to provide as much utility "for free" once an
# inteface has been adequately defined, for example maybe something like good
# old form generation or help screen generation, or helpful error messages.
#
# Something ridiculous would be to try to present dynamically a subset of the
# set of Abilities to a user given a field of parameters.  Probably
# totally useless but potentially nifty:
# A user might know that she has two slices of bread and 3 olives, but she
# might not know that we can whip up an avant garde minimal sandwich for her.
#
# In the end it's all about deriving meaning from streams of bits, trying
# to create new meaning from that, and turning it back into streams of bits
# for someone else to get new meaning from.  All of this might be
# totally useless but it's interesting, no?.
#
# "these are not within the parameters of my ability"
#
require 'ruby-debug'

module Hipe
  module Interfacey
    module Exception; end
    class ArgumentError < ::ArgumentError; include Exception end
    class RuntimeError < ::RuntimeError; include Exception end
    class ApplicationArgumentError < ArgumentError; end
    class Paradigm < Struct.new(:module); end
    module Service
      def self.included mod
        class << mod
          attr_accessor :interface
        end
        mod.interface = Interface.new(mod)
      end
    end
    class Interface
      attr_reader :abilities, :can_speak, :default_request
      def initialize implementor
        @default_request = nil
        @abilities = AssociativeArray.new.no_clobber.require_key
        @implementor_class = implementor
        @speaks = AssociativeArray.new.no_clobber.require_key
      end
      # @oldschool-setter-getter
      def speaks paradigm_name=nil
        return @speaks.keys.dup if paradigm_name.nil?
        case paradigm_name
        when :cli
          if ! @speaks.has_key?(:cli)
            require 'hipe-core/interfacey/optparse-bridge'
            para = Paradigm.new(Cli)
            @speaks[:cli] = para
            para.module.init_service_class @implementor_class
          end
        else
          raise ArgumentError.new("can't speak #{paradigm_name.inspect}")
        end
      end
      def _speaks
        @speaks
      end
      def can_speak? paradigm
        @speaks.has_key? paradigm
      end
      def responds_to *args, &proc
        ability = Ability.new(args, @speaks, &proc)
        @abilities[ability.name] = ability
      end
      #
      # note that caller can set a request name and parameters:
      # interface.default_request = 'foo', {'bar'=>'baz'}
      def default_request=(args)
        @default_request = RequestLite.new(args)
      end
      def default_request
        @default_request || RequestLite.new(nil)
      end
      def on_method_missing(impementing_object, ability, request)
        @speaks.each do |paradigm|
          defaults = paradigm.module.const_get('DefaultImplementations')
          if defaults.respond_to?(ability.method_name)
            return defaults.send(
              ability.method_name,
              impementing_object,
              self,
              ability,
              request
            )
          end
        end
        raise ArgumentError.new("please implement #{ability.method_name}")
      end
    end
    class Ability
      NameRe = %r|^([[:space:]]*[a-z][-a-z0-9_]+[[:space:]]*)(.*)$|
      attr_accessor :method_name
      attr_reader :name, :parameters, :speaks, :desc
      def initialize(args, speaks=nil, &proc)
        args = [args] if String===args
        @speaks = speaks
        @parameters = AssociativeArray.new.no_clobber.require_key
        opts = args.last.kind_of?(Hash) ? args.pop : nil
        first_string = args.shift
        parse_in_first_string first_string
        parse_in_args args
        @desc ||= []
        if opts
          @speaks.keys.each do |speaks|
            method = "#{speaks}_parse_in_opts!"
            send(method, opts) if respond_to? method
          end
          raise ArgumentError.new(
            "Unexpected opt(s):",opts.keys.map{|x| x.to_s} * ', '
          ) if opts.size > 0
        end
        merge_in_definition(&proc) if proc
      end
      # this gets superceded by cli
      def parse_in_first_string string
        (md = NameRe.match(string) and md[2] == "") or
          raise ArgumentError.new("bad name: #{string.inspect}")
        @name = md[1].strip
      end
      def parse_in_args args
        raise ArgumentError.new("expecting description array") if
          args.detect{|x| !String===x}
        @desc = args
      end
      def name=(name)
        raise ArgumentError.new("names can only be set once") if @name
        @name = name
      end
      def merge_in_definition &block
        definition = AbilityDefinitionContext.new self
        @speaks.keys.each do |speak|
          definition.send("#{speak}_before_ability_definition")
        end
        raise ArgumentError.new("Ability definition blocks don't take "<<
        %{arguments for now (ability: "#{name}")}) if block.arity > 0
        definition.instance_eval(&block)
        @speaks.keys.each do |speak|
          definition.send("#{speak}_after_ability_definition", self)
        end
        @parameters.merge_strict_recursivesque! definition.parameters
      end
      def self.methodize name
        name.to_s.gsub('-','_')
      end
      def method_name
        @method_name || Ability.methodize(name)
      end
    end
    class ParameterDefinition
      attr_reader :required, :desc, :name
      alias_method :required?, :required
      def subset? other
        name == other.name && required? == other.required?
      end
      Opts = {:default=>1}
      Types = {:optional=>1, :required=>1}
      def self.from_definition_block type, name, *args
        if Types[type]
          param = ParameterDefinition.new
          param.init_from_definition_block type, name, *args
          param
        end
      end
      def init_from_definition_block type, name, *args
        extend case type
          when :optional: OptionalParameter
          when :required: RequiredParameter
        end
        opts = args.last.kind_of?(Hash) ? args.pop : {}
        opts.each do |key,value|
          raise ArgumentError.new("unrecognzied option: #{key}") unless
            Opts[key]
          self.send("#{key}=", value)
        end
        unless Ability::NameRe =~ name
          raise ArgumentError.new("invalid #{type} name: #{name.inspect}")
        end
        @cli_type = type
        @name = name
        if (invalid = args.detect{|x| ! (String === x) })
          raise ArgumentError.new("For now, only description strings "<<
            "are supported in parameter definitions, not: #{invalid.inspect}")
        end
        @desc = args
      end
    end
    module Defaultable
      attr_accessor :default
      def default_defined?
        instance_variable_defined? '@default'
      end
    end
    module OptionalParameter
      include Defaultable
    end
    module RequiredParameter
    end

    # This class provides an execution context in which the body
    # of ability defintions are executed.  The individual paradigms
    # (cli etc.) might define methods for it.
    # this is similar to but not the same as an AbilityParseTree in cli,
    # similar in that it produces a list of parameter definitions, different
    # in that it yeilds it apis to the caller, instead of parsing a string.
    class AbilityDefinitionContext
      attr_reader :parameters, :name, :ability
      def initialize ability
        @parameters = AssociativeArray.new.no_clobber.require_key
        @ability = ability
      end
      def required(name,*args)
        param =
          ParameterDefinition.from_definition_block(:required, name, *args)
        @parameters[param.name] = param
      end
      def optional(name,*args)
        param =
          ParameterDefinition.from_definition_block(:optional, name, *args)
        @parameters[param.name] = param
      end
    end

    # this might become a plain old class, not a struct
    class RequestLite < Struct.new(
        :name,
        :unparsed_parameters,
        :parsed_parameters
    )
      def initialize args
        if args.nil?
          self.name = nil
          self.unparsed_parameters = nil
        elsif args.kind_of? String
          self.name = args
          self.unparsed_parameters = nil
        elsif args.respond_to? :keys
          my_args = args.dup
          self.name = my_args.delete('request-name')
          self.unparsed_parameters = my_args
        elsif args.respond_to? :shift
          my_args = args.dup
          self.name = my_args.shift
          self.unparsed_parameters = my_args
        else
          raise ArgumentError.new("Can't figure out how to create a request"<<
          " from #{args.inspect}")
        end
      end
      def empty?
        name.nil? &&
          (unparsed_parameters.nil? || unparsed_parameters.empty?)
      end
    end

    class ResponseLite
      attr_reader :original_exception, :errors, :messages
      def initialize(args=nil)
        @errors = []
        @messages = []
        if args
          @errors.push(args.delete(:error)) if args[:error]
          @messages.push(args.delete(:message)) if args[:message]
          @original_exception = args.delete(:original_exception) if
            args[:original_exception]
          raise ArgumentError.new("no: "+args.keys.map{|x|x.to_s}) if
            args.keys.size > 0
        end
      end
      def puts str
        @messages.push str.sub(/\n\z/, '')
      end
      def << str
        if (@messages.size == 0)
          @messages.push ""
        end
        @messages.last << str
      end
      def valid?
        @errors.size == 0
      end
      def to_s
        if valid?
          @messages * "\n"
        else
          @errors * "\n"
        end
      end
    end

    # OrderedHash can be annoying.  This achieves what we want in 10% sloc.
    # additional features: no_clobber, merge_strict_recursivesque!,
    # require_key (meaning non Fixnum, non nil key), attr_accessors
    # (sort of open struct-like)
    # @todo - move this to hipe-core/struct/ if you want to use it elsewhere
    # but why should you? you will always want to use Interfacey too!
    class AssociativeArray < Array
      # when we eventually need any methods from the below list we will have
      # to deal with @keys and @keys_order.  Trivial but crufty until needed.
      undef :delete, :delete_at, :pop, :reject!, :replace, :shift, :slice!,
        :sort, :sort!
      def initialize
        super
        @require_key = false
        @clobber = true
        @keys = {}
        @keys_order = []
      end
      alias_method :orig_store, :[]=
      alias_method :orig_fetch, :[]
      def []=(key, thing)
        if (!@clobber && (key.class==Fixnum) ?
          (i < length) : @keys.has_key?(key))
          raise @clobber_exception_class.new("Won't clobber #{key.inspect}")
        end
        if (@require_key and !key || key.kind_of?(Fixnum))
          raise ArgumentError.new("This array required a non-numeric "<<
          "key, not #{key.inspect}")
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
      def clear
        super
        @keys_order.clear
        @keys_clear
      end
      def keys;          @keys_order.dup             end
      def has_key? key;  !! @keys[key]               end
      def require_key;  @require_key = false; self end
      def no_clobber(throw_class=nil)
        @clobber = false;
        @clobber_exception_class = throw_class || ApplicationArgumentError
        self
      end

      # Unlike OpenStruct, we clobber any existing method names. Careful!
      def attr_accessors(*names)
        names.each do |name|
          meta = class << self; self; end
          meta.send(:define_method, name) { self[name] }
          meta.send(:define_method, :"#{name}=") { |x| self[name] = x }
        end
      end

      def to_hash
        flippo = @keys.invert
        hash = {}
        each_with_index do |value, idx|
          if flippo.has_key?(idx)
            hash[flippo[idx]] = value
          else
            hash[idx] = value
          end
        end
        hash
      end

      # very experimental!  requires that other array have keys
      # for each of its elements. (We could change this if we made)
      # this class more set-like, that is, require hash() and eql?()
      # on each element.)
      # This tries to append each other element in its foreign order
      # to the end of this array, using its key; if we don't have the key.
      # If this array already has the key, this will either replace
      # or ignore the other value based on which one is a subset of the other.
      # (the one that is a subset wins, it has more information.)
      # An ArgumentError is raised if neither value is a subset of the other.
      # The really cool thing to do would be define and use set union.
      # it is called "recursivesque" because it only goes down this one level
      # (for now)
      def merge_strict_recursivesque! assoc_array
        other_keys = assoc_array.keys
        if (other_keys.length != assoc_array.length)
          raise ArgumentError.new(
            "for now, other array must be %100 hash-like")
        end
        other_keys.each do |key|
          other_value = assoc_array[key]
          if ! has_key? key
            self[key] = other_value
          elsif self[key].subset? other_value
            # nothing
          elsif other_value.subset? self[key]
            self[key] = other_value
          else
            raise ArgumentError.new( "Can't merge at key #{key.inspect} - "+
              "this value is neither subset nor superset of the other.")
          end
        end
      end
    end
    module Lingual
      # we didn't wan't a dependency on en.rb just for this,
      # and this revisits the interface
      module En
        # experimental -- would be better to have one object per object?
        def self.included mod
          speaker = Speakers::En.new
          mod.send(:define_method, :en){ speaker }
        end
      end
      module Speakers
        class Speaker; end
        class En < Speaker
          # oxford comma
          def join(list, sep1=', ', sep2=' and ', &block)
            list = list.map(&block) if block
            case list.size
            when 0 then 'nothing'
            when 1 then list[0]
            else
              joiners = ['',sep2]
              joiners += ::Array.new(list.size-2,sep1) if list.size >= 3
              list.zip(joiners.reverse).flatten.join
            end
          end
        end
      end
    end
    ValidMethodNameRe = /^[_a-z][_a-z0-9]*/i
    def self.valid_method_name? str
      ValidMethodNameRe =~ str
    end
  end
end
