##
# A class that includes Interfacey::Service will have one
# Intefacey::Interface. An Interface models the set
# (and list?) of (at times) "public" procedures
# the service reveals, called Abilities.
#
# A set of Abilities defines the set of requests (Requests?) that the
# implementing class can respond_to through its Interface.
# (We are using "set" and "list" here sort of on purpose.)
#
# An Ability has a name (string not symbol), and a set (list?) of zero
# or more ParameterDefinition s. (Not called "Parameters" to avoid confusion
# with the parameters of an individual request.)
#
# An Abilty can have zero or more aliases, also strings.
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

    # all exceptions thrown by Interfacey will be a kind_of? this
    module Exception; end

    class ArgumentError < ::ArgumentError; include Exception end

    class RuntimeError < ::RuntimeError; include Exception end

    class ApplicationArgumentError < ArgumentError; end

    class Paradigm < Struct.new(:name,:module); end

    # this defines the set of all class methods given to a class
    # that is a kind of Intefacey::Service
    module Service
      def self.included mod
        class << mod
          attr_accessor :interface
        end
        mod.interface = Interface.new(mod)
      end
    end

    module Describable
      # the same rules apply to interfaces, abilities, and their parameters
      # for setting and getting their description strings.

      # The name "desc" is borrowed from optparse, and is thus abbreviated
      # only for historical reasons.   For this same reason the description
      # is represented internally as an array of strings, which shouldn't
      # be a problem because while converting an array of strings to a string
      # is lossy, representing a string as an array of strings is not lossy,
      # in fact gainey.


      #
      # @param [String|Array] if String, will be run through the
      # common gsub/split routine.  If needed we can provide a way to
      # circumvent this.
      #
      # For now, this is non-clobbering, and will raise an ArgumentError
      # if there is any existing description.  Existing descriptions can be
      # cleared with thing.desc.clear.  If you want to for some reason merge
      # in to any existing description, you could thing.desc.concat(array)
      #
      # As for what is meant by "the common gsub/split routine" above:
      # We make some assumptions about what was intended in a string that
      # may have come from a multiline HEREDOC style string literal:
      # leading whitespace on the first line is indentation to make the code
      # pretty, not the outputted string pretty; all ouputted lines
      # of the string will thus have indentation reduced by this first
      # indentation.  (so you can still have meaningful indentation in your
      # multiline HEREDOC-style string if subsequent lines are indented
      # further than the first line.)  If this is not the desired behavior
      # we can consider making this somehow optional.
      #
      # Don't use tabs.  Ever. ;)
      #
      def desc= mixed
        raise ArgumentError.new("Won't clobber existing description") if
          (@desc && @desc.length > 0)
        if mixed.kind_of? Array
          desc = mixed
        elsif mixed.kind_of? String
          if mixed.index("\n")
            leading_whitespace = /^( *)/.match(mixed).captures[0]
            ws_re = Regexp.new('^'+leading_whitespace);
            desc = mixed.gsub(ws_re,'').split("\n").map{|x|x=="" ? " " : x}
              # optparse doesn't like empty strings in @desc.  try it!
            # despite attempts at negative look-ahead above, we couldn't
            # preserve intentional trailing newlines in the description guy
            # because 'AAAAA'.split('A') => []
            if desc.length > 0 && md = /(\n+\Z)/.match(mixed)
              desc.last.concat(md[1])
            end
          else
            desc = [mixed]
          end
        else
          raise ArgumentError.new("bad class for description: #{mixed.class}")
        end
        self.desc.concat desc # we keep our original object
        on_desc_change if respond_to? :on_desc_change
        @desc
      end

      # @oldschool setter getter
      def desc mixed=nil
        if mixed.nil?
          @desc ||= []
        else
          self.desc = mixed
        end
      end

      alias_method :describe, :desc
    end

    # "hideable" ? neither of these are "words". "visible" is a misnomer
    module Visable
      attr_accessor :visible
      alias_method :visible?, :visible
      def hidden
        ! @visible
      end
      def hidden= val
        @visible = ! val
      end
      alias_method :hidden?, :hidden
      def show
        @visible = true
      end
      def hide
        @visible = false
      end
    end

    class Interface
      include Describable
      attr_reader :default_request

      def initialize implementor
        @desc = nil
        @default_request = nil
        @abilities = Abilities.new
        @implementor_class = implementor
        @speaks = AssociativeArray.new.require_key.
          no_clobber(ArgumentError)
      end

      # @oldschool-setter-getter
      def speaks paradigm_name=nil
        return @speaks.keys.dup if paradigm_name.nil?
        case paradigm_name
        when :cli
          if ! @speaks.has_key?(:cli)
            require 'hipe-core/interfacey/optparse-bridge'
            para = Paradigm.new(:cli, Cli)
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

      def speaks? paradigm
        @speaks.has_key? paradigm
      end

      def responds_to *args, &proc
        Ability.create_or_merge(@abilities, args, @speaks, &proc)
      end

      def responds_to? mixed, paradigm=nil
        self.abilities(:paradigm=>paradigm, :request=>mixed).size > 0
      end

      # @return nil if no abilities found, ability if one found,
      # raise ArgumentError if more than one ability matched
      def ability_for_request mixed, paradigm
        abilities = self.abilities(
          :paradigm => paradigm, :visible => true, :request => mixed
        )
        case abilities.size
          when 0: nil
          when 1: abilities[0]
          else raise ArgumentError(
            %|ambiguous inteface grammar -- |<<
            %|more than one ability for %{name}|
          ) # this might never happen depending on how we
          # implement aliases.
        end
      end


      # @return [Array] of matched abilities given
      # @param [Hash] a query of the form:
      #   [:paradigm => Symbol], [:visible => Boolean], [:request=> mixed]
      #
      # :request must either be a String or respond_to?(:name)
      #
      def abilities query={}
        visible    = query[:visible]
        paradigm   = query[:paradigm]
        name       = query[:request] ?
          (query[:request].kind_of?(String) ?
            query[:request] : query[:request].name
          ) : nil

        # we could speed this up by using the assoc. array key but why?
        @abilities.select do |ability|
          (visible.nil? ? true :
            (ability.visible? == visible)
          ) &&
          (paradigm.nil? ? true :
            ability.speaks?(paradigm)
          ) &&
          (name.nil? ? true :
            (ability.name == name ? true :
              (ability.aliases ?
                ability.aliases.include?(name) :
                false
              )
            )
          )
        end
      end

      # note that caller can set a request name and parameters:
      # interface.default_request = 'foo', {'bar'=>'baz'}
      def default_request= args
        @default_request = RequestLite.new args
      end

      # @oldschool setter-getter
      def default_request args=nil
        if args
          self.default_request = args
        else
          @default_request || RequestLite.new(nil)
        end
      end

      def might &block
        instance_eval(&block)
      end

      def create_response_context app_instance, speaks
        context_class = @speaks[speaks].module.const_get('ResponseContext')
        # looking for ResponseContext.new() ?
        context_class.new speaks, self, app_instance
      end
    end

    class Ability
      include Describable, Visable
      NameRe = %r|^([[:space:]]*[a-z][-a-z0-9_]+[[:space:]]*)(.*)$|
      attr_reader :name, :parameters, :speaks, :aliases
      attr_accessor :definition_context
      # aliases is defind above but not supported out of the box @todo

      #
      # @param [AssociativeArray] existing_assoc existing abilities
      #   keyed by name
      # @see initialize() for the remaining parameters
      #
      def self.create_or_merge(existing_assoc, args, speaks, &proc)
        new_ability = new(args, speaks, &proc)
        if ability = existing_assoc[new_ability.name]
          ability.merge_in! new_ability
          result = ability
        else
          result = new_ability
          existing_assoc[new_ability.name] = new_ability
        end
        result
      end

      def initialize(args, speaks=nil, &proc)
        args = [args] if String===args
        @visible = true
        @speaks = speaks
        @parameters = Parameters.new
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
          parse_in_opts! opts
          raise ArgumentError.new(
            "unhandled opt(s):" + opts.keys.map{|x| x.to_s} * ', '
          ) if opts.size > 0
        end
        merge_in_definition(&proc) if proc
      end

      def define &proc
        merge_in_definition(&proc)
      end

      def speaks? paradigm_name
        @speaks && @speaks.has_key?(paradigm_name)
      end

      def merge_fail(msg)
        raise ArgumentError.new("merge failure: #{msg}")
      end

      #
      # for when abilties have been "re-opened", (for dealing with having long
      # descriptions of paramters happening in their own statements.)
      # This might also be useful if an appication object wants to add
      # parameter definitions to an existing ability ''dynamically''.
      # In theory it could also be relevant if we ever deal with (ick)
      # interface ''inheiritance''.
      # This will attempt to render the passed ability useless and empty,
      # and raise a failure when there are instance_variables we have
      # forgotten about.
      #
      # @todo over in cli we will figure out a way to use the same
      #
      def merge_in! other
        return merge_fail(%|can't merge-in an ability with a different |<<
          %|name (mine: "#{name}", other: "#{other.name}")|) unless
            other.name == name
        other.instance_variable_set('@name',nil)
        merge_in_speaks! other
        speaks.keys.each do |key|
          self.send(%{#{key.to_s}_merge_in!},other)
        end
        @visible = other.visible?; other.visible = nil
        # @todo the below is a bit expensive with delete turned on!
        @parameters.merge_strict_recursivesque!(other.parameters,:delete=>1)
        merge_in_desc! other
        merge_off_definition_context! other
        unless other.empty?
          members = other.non_empty_members
          msg = members.map{|pair| %|#{pair[0]} : #{pair[1].class}| }*', '
          return merge_fail("not empty in source after merge: "+msg)
        end
        nil
      end

      # @api private
      def merge_in_speaks! other
        # totally insane.  The new defined ability must know about
        # previous paradigms the existing ability speaks.
        missing = speaks.keys - other.speaks.keys
        newkeys = other.speaks.keys - speaks.keys
        if missing.size > 0
          return merge_fail(%|for now, the new definition of #{name} must| <<
          %| speak a superset of what the old definition spoke (missing:| <<
          %| #{missing.keys.map{|x| x.to_s}*', '})|)
        end
        newkeys.each do |key|
          @speaks[key] = other.speaks[key]
        end
        # @todo why are these the same object? should they be?
        if speaks.object_id == other.speaks.object_id
          other.instance_variable_set('@speaks',nil)
        else
          other.speaks.clear
        end
      end

      # @api private
      def merge_in_desc! other
        if (other.desc.size > 0)
          self.desc = other.desc   # raises on clobber
          other.desc.clear
        end
      end

      # @api private
      def merge_off_definition_context! other
        # this is ridiculous. For now, we don't care about taking the other
        # definition context from the other ability (we don't really care
        # care about our own, (if we have one) either), but when --help is
        # called as an option it has to be able to reach up to the correct
        # ability object, so here the definition context becomes
        # an orphan floating in memory, (it was before, too)
        # but has a handle to this new ability object (self).
        ctx = other.definition_context or return
        ctx.ability = self
        other.definition_context = nil
        nil
      end

      # @return [Array[Array]] pairs of ivar names and values, nil if empty
      def non_empty_members
        not_empty = []
        instance_variables.each do |name|
          var = instance_variable_get name
          if ( !var.nil? and ! var.respond_to?(:empty?) || ! var.empty? )
            not_empty.push [name, var]
          end
        end
        not_empty.size > 0 ? not_empty : nil
      end

      def empty?
        ! non_empty_members
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

      def parse_in_opts! opts
        if opts[:desc]
          self.desc = opts.delete(:desc)
        end
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
        @definition_context = definition
      end

      def method_name
        @method_name || Interfacey.methodize(name)
      end
    end

    class ParameterDefinition
      include Describable # one day Visable
      attr_reader :required, :name
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

    #
    # This provides an execution context in which the body
    # of ability defintions are executed.  The individual paradigms
    # (cli etc.) might define methods for it.
    # this is similar to but not the same as an AbilityParseTree in cli,
    # similar in that it produces a list of parameter definitions, different
    # in that it yeilds it apis to the caller, instead of parsing a string.
    #
    class AbilityDefinitionContext
      attr_reader :parameters, :name
      attr_accessor :ability
      def initialize ability
        @parameters = AssociativeArray.new.require_key.
          no_clobber(ArgumentError)
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

    class ResponseContext
      # a ResponseContext is a way to corral all the error handling
      # for pre-processing a request (determining method name, etc)
      # in one place, and allow variations to them among the paradigms.
      # it started because cli_run started to get too long and we wanted
      # to break it up, and it felt weird adding all these to the application
      # or the interface. one day we will deal with how to give hooks to the
      # implememtor, it will probably of the form:
      # "on_<paradigm>_<error-name>(...)", like if the implementor defines
      # on_cli_method_missing(...) that will be used instead.

      attr_accessor :request, :ability

      def initialize paradigm_name, interface, app_instance
        @paradigm_name = paradigm_name
        @interface = interface
        @app_instance = app_instance
        @ability = nil
        @request = RequestLite.new(nil)
          # just in case it isn't set before we need it @todo necessary?
      end

      def paradigm
        @interface._speaks[@paradigm_name]
      end

      # this happens only when there is no default request or the default
      # request is also empty (empty meaning no name and no parameters)
      # this must return a response with one error message.  paradigms
      # can change this but they might call up to this.
      def on_empty_request
        ResponseLite.new(:error=>"empty request")
      end

      # can't find an ability to match the request name
      def on_cannot_respond_to
        ResponseLite.new(
          :error=>%{i don't know how to respond to "#{@request.name}"})
      end

      # ApplicationArgumentError is a class created for us to throw
      # inteface-level interaction errors, like handling unexpected parameters
      # or missing required parameters. This is called to handle when
      # exceptions of those class are thrown.  Whether or not to present the
      # error to the user is something that the paradigm or implementing class
      # should define. Cli, for example, will probably want to display to the
      # user something like "please see <command-name> -h for more
      # information.", but in a rack context this might be something to
      # log to an error file.
      def on_application_argument_error e
        ResponseLite.new(:error=>e.to_s, :original_exception=>e)
      end

      # the implementing object doesn't respond to a method name corresponding
      # to the ability name, but the ability has been defined.
      def on_method_missing
        defaults = paradigm.module.const_get('DefaultImplementations')
        if defaults.respond_to? @ability.method_name
          return defaults.send( @ability.method_name,
            @interface, @app_instance, @ability, @request)
        end
        raise ArgumentError.new("please implement #{@ability.method_name}")
      end

      # similar to above.
      def on_arity_mismatch method_arity, args_size
        raise ArgumentError.new(
          "expecting #{@app_instance.class}##{method} to take to take "<<
          "#{args.size} arguments per the definition.  Its arity is "<<
          " #{arity}.")
      end
    end

    # OrderedHash can be annoying.  This achieves what we want with less sloc.
    # additional features: no_clobber, custom messages on clobber,
    # require_key (meaning non Fixnum, non nil key),
    # merge_strict_recursivesque!,  attr_accessors (sort of open struct-like)
    # @todo - move this to hipe-core/struct/ if you want to use it elsewhere
    # but why should you? you will always want to use Interfacey too!
    class AssociativeArray < Array

      class ClobberError < RuntimeError; end

      # when we eventually need any methods from the below list we will have
      # to deal with @keys and @keys_order.  Trivial but crufty until needed.
      undef :pop, :reject!, :replace, :shift, :slice!,
        :sort, :sort!

      alias_method :orig_delete_at, :delete_at
      undef :delete_at # ! terrible

      def initialize
        super
        @require_key = false
        @clobber = true
        @clobber_message = nil
        @keys = {}
        @keys_order = []
      end
      alias_method :orig_store, :[]=
      alias_method :orig_fetch, :[]
      attr_accessor :clobber_message
      def []=(key, thing)
        if (!@clobber && (key.class==Fixnum) ?
          (i < length) : @keys.has_key?(key))
          raise @clobber_exception_class.new(sprintf(clobber_message,key))
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
        (key.class==Fixnum) ? orig_fetch(key) :
        has_key?(key) ? orig_fetch(@keys[key]) : nil
      end
      def clear
        super
        @keys_order.clear
        @keys_clear
      end

      # in the future we might expand this to take indexes
      # note this redefines parent to not take a block.
      def delete key
        if @keys[key]
          key_idx = @keys.delete(key)
          @keys.select do |k,v|
            v > key_idx
          end.each do |k,v|
            @keys[k] -= 1
          end
          @keys_order.delete_at @keys_order.index(key)
          orig_delete_at key_idx
        else
          nil
        end
      end

      def keys;          @keys_order.dup             end
      def has_key? key;  @keys.has_key?(key)         end
      def require_key;   @require_key = true; self   end
      def no_clobber(throw_class=nil)
        @clobber = false;
        @clobber_exception_class = throw_class || ClobberError
        self
      end

      def clobber_message
        @clobber_message ||= "Won't clobber %s"
      end

      # Unlike OpenStruct, we clobber any existing method names. Careful!
      def attr_accessors(*names)
        names.each do |name|
          method_name = Interfacey.methodize(name)
          meta = class << self; self; end
          meta.send(:define_method, method_name) { self[name] }
          meta.send(:define_method, :"#{method_name}=") { |x| self[name] = x }
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

      def dup
        nu = super
        %w(@keys @keys_order).each do |it|
          nu.instance_variable_set it, instance_variable_get(it).dup
        end
        %w(@require_key @clobber).each do |it|
          nu.instance_variable_set it, instance_variable_get(it)
        end
        nu
      end

      # very experimental!  requires that other array have keys
      # for each of its elements. (We could change this if we made)
      # this class more set-like, that is, require hash() and eql?()
      # on each element.)
      # This tries to append each other element in its foreign order
      # to the end of this array, using its key; if we don't have the key.
      # If this array already has the key, this will either replace
      # or ignore the other value based on which value is a subset() of the
      # other.  (the one that is a subset wins, it has more information.)
      # An ArgumentError is raised if neither value is a subset of the other.
      # The really cool thing to do would be define and use set union.
      # it is called "recursivesque" because it only goes down this one level
      # (for now)
      def merge_strict_recursivesque! other, opts={}
        do_delete = opts.has_key?(:delete) ? opts[:delete] : false
        other_keys = other.keys
        if (other_keys.length != other.length)
          raise ArgumentError.new(
            "for now, other array must be %100 hash-like")
        end
        other_keys.each do |key|
          other_value = do_delete ? other.delete(key) : other[key]
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

    class Abilities < AssociativeArray
      def initialize
        super
        require_key.no_clobber(ArgumentError)
      end
    end

    class Parameters < AssociativeArray
      def initialize
        super
        require_key.no_clobber(ArgumentError)
      end
    end

    module Lingual
      # we didn't wan't a dependency on en.rb just for this,
      # and this revisits the interface.  It will probably move
      # into an "nl" submodule.

      module En
        SpTerminationPunctuation      = /[\.?!]/
        PhraseTerminationPunctuation  = /[;,]/

        # experimental -- would be better to have one object per object?
        def self.included mod
          speaker = Speakers::En.new
          mod.send(:define_method, :en){ speaker }
        end

        def self.is_sentence_terminating_punctuation? fixnum
          SpTerminationPunctuation =~ fixnum.chr
        end

        def self.punctuate! string
          if (
            string.length > 0 &&
            ! is_sentence_terminating_punctuation?(string[string.length-1])
          )
            string.concat '.'
          end
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
    def self.methodize name
      name.to_s.gsub('-','_')
    end
  end
end
