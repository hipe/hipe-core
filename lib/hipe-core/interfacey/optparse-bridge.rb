# syntagm

# half of this is to bridge to optparse, half is to parse ability
# definitions from syntax summary strings (in the "git" format)
#
# to use this please be familiar with OptionParser and see the example in
# /bin
#

require 'optparse'
module Hipe::Interfacey
  module RequiredParameter
    CliRegexp = %r{^[[:space:]]*<([_a-z][-_a-z0-9]*)>[[:space:]]*}
    def cli_unparse; "<#{@name}>" end
    alias_method :inspect, :cli_unparse
    alias_method :to_s, :cli_unparse
  end

  module OptionalParameter
    CliRegexp = %r{^[[:space:]]*\[<([_a-z][-_a-z0-9]*)>\][[:space:]]*}
    def cli_unparse; "[<#{@name}>]" end
    alias_method :inspect, :cli_unparse
    alias_method :to_s, :cli_unparse
  end

  class Ability
    attr_accessor :cli_optparse_proxy
    attr_reader :cli_aliases
    # factory constructor.
    # note that with this form we can't pass blocks. kind of useless
    # except for making it look pretty when testing
    def self.[](string)
      Ability.new(string,[:cli=>Cli])
    end
    def cli_parse_in_opts! opts
      if opts[:aliases]
        @cli_aliases = opts.delete(:aliases)
      end
      nil
    end
    # throw on unparsable string
    def parse_in_first_string string
      struct = Cli::AbilityParse.new.parse string
      @name = struct.name
      @parameters.merge_strict_recursivesque! struct.parameters
      nil
    end
  end

  class AbilityDefinitionContext
    # instance methods defined here are available in the definition blocks
    attr_reader :optparse_proxy
    def cli_before_ability_definition
      opt_parser = OptionParser.new
      @optparse_proxy = Cli::OptionParserProxy.new(opt_parser, self)
    end
    def opts;  @optparse_proxy  end
    def cli_after_ability_definition ability_definition
      accessors = []
      parameters.each do |param|
        next unless :switch == param.cli_type
        accessors << param.name if
          Hipe::Interfacey.valid_method_name?(param.name)
      end
      if @optparse_proxy.num_things > 0
        ability_definition.cli_optparse_proxy = @optparse_proxy
        @optparse_proxy.parse_context.result.attr_accessors(*accessors)
      end
    end
    def help
      # flagrant hack
      definition_context = self
      lambda do
        by_type = Hash.new{|hash, key| hash[key] = []}
        definition_context.parameters.each do |param|
          by_type[param.cli_type] << param
        end
        orig_optparser = definition_context.optparse_proxy.option_parser
        optparse = orig_optparser.dup
        class << optparse;
          attr_accessor :stack
          def last; @stack[2].instance_variable_get('@list').last end
          def _banner; @banner end
        end
        unless optparse._banner
          banner =
          [
            "usage: #{optparse.program_name}",
            "#{definition_context.ability.name}",
            by_type[:switch].map{|x| x.cli_unparse}*' ',
            by_type[:required].map{|x| x.cli_unparse}*' ',
            by_type[:optional].map{|x| x.cli_unparse}*' '
          ].reject{|x|""==x} * ' '
          optparse.banner = banner
        end
        optparse.stack = orig_optparser.instance_variable_get('@stack').dup
        these = [:required, :optional, :splat]
        if these.map{|x| by_type[x].size }.reduce(:+) > 0
          these.each do |cli_type|
            by_type[cli_type].each do |param|
              # we need to give the swith a unique name even tho we rewrite it
              optparse.on("--#{param.name}", *param.desc)
              switch = optparse.last
              switch.instance_variable_set('@long',[param.cli_unparse])
            end
          end
        end
        response = optparse.to_s
        Cli.add_linebreaks_to_syntax_summary! response
        throw :cli_early_exit, response
      end
    end
    def version
      lambda do
        puts "i am version"
        throw :cli_early_exit, ""
      end
    end
  end
  module Cli

    def self.init_service_class implementor
      implementor.send :include, Run
    end

    # if the syntax summary line (matching "usage:..") is longer than any
    # other line, try to break the summary after ] or (> not followed by ])
    # whichever you find first, such that the new newlines you insert have
    # a (hard-coded for now) indent after them and the resulting lines are
    # not longer than the max_width.  easy.
    def self.add_linebreaks_to_syntax_summary! banner
      indent = ' '*4 # hardcoded in optparse too :/
      lines = banner.split("\n")
      idx = lines.index{|x| x=~ /^ *usage:/}
      return unless idx
      summary_line = lines[idx]
      lines_before_summary = lines.slice(0,idx)
      lines_after_summary = lines.slice(idx+1, lines.length)
      return unless lines_after_summary
      lines_wo_summary = lines_before_summary + lines_after_summary
      max_width = lines_wo_summary.map{|x| x.length}.max
      max_width = [40, max_width].max  # let's not be ridiculous
      return if summary_line.length <= max_width
      re =/^
        (.{1,#{max_width-1}}\]|.{1,#{max_width-2}}>(?!\]))
        [[:space:]]*
        (.+)
      /x
      return unless md = summary_line.match(re)
      first_line = md[1]
      remainder = md[2]
      new_max_width = max_width - indent.length
      re = /
        [[:space:]]*
        (.{1,#{new_max_width-1}}\]|.{1,#{new_max_width-2}}>(?!\]))
      /x
      remainder = indent + remainder.gsub(re,"\\1\n#{indent}")
      banner.replace [ lines_before_summary,
        first_line,
        remainder,
        lines_after_summary
      ].flatten * "\n"
      nil
    end
    class RequestParse
      include Lingual::En

      # this manages the parsing of an individual request, running the opts
      # thru optparse, complaining if required parameters don't exist,
      # and complaining about anything that it can't parse on the
      # input array once it gets to the end of its grammar

      # @return [RequestLite] the provided request,
      # eat off the unparsed_parameters and create an array at
      # parsed_parameters
      @@singleton = new
      def self.parse_request! ability, request
        @@singleton.parse_request! ability, request
        nil
      end

      def parse_request! ability, request
        @ability = ability
        @by_type = Hash.new{|hash,key| hash[key] = []}
        ability.parameters.each do |param|
          @by_type[param.cli_type] << param
        end
        switches = parse_off_switches ability.cli_optparse_proxy, request
        argv = [
          parse_off_requireds(request),
          parse_off_optionals(request)
        ].flatten
        argv.push(switches) if switches
        if request.unparsed_parameters.size > 0
          s = (request.unparsed_parameters.size > 1) ? 's' : ''
          raise ApplicationArgumentError.new("unexpected parameter#{s}: "<<
            (request.unparsed_parameters * ', '))
        end
        request.parsed_parameters = argv
        nil
      end

      # @return [AssociativeArray|nil] nil if there are no defined switches
      def parse_off_switches proxy, request
        return nil unless @by_type.has_key?(:switch)
        # remember there is only ever one optparser in memory per ability
        proxy.parse_context.result.clear
        begin
          proxy.option_parser.parse!(request.unparsed_parameters)
          proxy.option_parser.parse!(make_switch_default_argv(proxy))
        rescue OptionParser::ParseError => e
          raise Cli::OptparseParseError.new(e)
        end
        parse_result = proxy.parse_context.result.dup # multiple invocations?
        proxy.parse_context.result.clear # just to be safe we do it twice
        parse_result
      end

      # @return an argv-like array of key-value pairs for all the switches
      # defined with defaults that were not in the provided argv
      def make_switch_default_argv proxy
        provided_keys = proxy.parse_context.result.keys
        @by_type[:switch].select do |param|
          param.default_defined? &&
          ! provided_keys.include?(param.name)
        end.map do |param|
          [ param.name_as_switch, param.default ]
        end.flatten
      end

      def parse_off_optionals request
        # return one array element for every defined optional positional,
        # populating defaults positionally as necessary, or
        # nil if the argument was not provided and there are no defaults
        list = @by_type[:optional]
        return [] if list.length == 0
        min = [list.size, request.unparsed_parameters.size].min
        result = request.unparsed_parameters.slice!(0, min) # (0,0) ok
        if result.length < list.length
          (result.length .. (list.length-1)).each do |i|
            param = list[i]
            result[i] =  param.default_defined? ? param.default : nil
          end
        end
        result
      end

      def parse_off_requireds request
        list = @by_type[:required] # length 0 ok
        if request.unparsed_parameters.size < list.size
          missing = list.slice(request.unparsed_parameters.size, list.size)
          raise ApplicationArgumentError.new(
            "What about " << en.join(missing){|x| x.name} << '?'
          )
        end
        request.unparsed_parameters.slice!(0, list.size) #(0,0) ok
      end
    end

    class OptparseParseError < ApplicationArgumentError
      # just a wrapper to unify the kinds of runtime errors we throw
      attr_reader :original_exception
      def initialize(original_exception)
        super(original_exception.to_s)
        @original_exception = original_exception
      end
    end
    class OptionParsingExecutionContext
      attr_reader :result
      def initialize proxy
        @proxy = proxy
        @result = AssociativeArray.new.no_clobber.require_key
      end
      def clear
        @result.clear
      end
    end
    class OptionParserProxy
      # this thing allows users to say opts.on(...) in their definitions
      # and still we can route the defined options into our definition
      # structure
      attr_reader :option_parser, :parse_context, :num_things
      attr_accessor :result
      def initialize option_parser, ability_definition
        @num_things = 0
        @option_parser = option_parser
        @list_hack = @option_parser.instance_variable_get('@stack')[2].list
        @defined_parameters = ability_definition.parameters
        @parse_context = OptionParsingExecutionContext.new(self)
      end
      def banner *args, &block
        @num_things += 1
        @option_parser.banner(*args, &block)
      end
      def separator *args, &block
        @num_things += 1
        @option_parser.separator(*args, &block)
      end
      # should probably use builtin help instead
      def to_s
        @option_parser.to_s
      end
      def on *args, &user_block
        @num_things += 1
        my_opts = args.last.kind_of?(Hash) ? args.pop : nil
        orig_result = @option_parser.on(*args)  # we don't give it a block yet
        switch = @list_hack.last  # the switch just added above
        my_switch = ParameterDefinition.from_optparse_switch switch, my_opts
        # if the user didn't provide a block in the definition, the default ..
        user_block ||= lambda{|value| value} # is just to return the value
        if my_switch.many?
          use_this_block = lambda do |value|
            value = @parse_context.instance_exec(value, &user_block)
            unless result.has_key?(my_switch.name)
              @parse_context.result[my_switch.name] = []
            end
            @parse_context.result[my_switch.name] = []
          end
        else
          use_this_block = lambda do |value|
            value = @parse_context.instance_exec(value, &user_block)
            @parse_context.result[my_switch.name] = value
          end
        end
        switch.instance_variable_set('@block', use_this_block)
        @defined_parameters[my_switch.name] = my_switch # throws on clobber
        orig_result
      end
      def on_tail *args, &block
        @num_things += 1
        @option_parser.on_tail(*args, &block)
      end
    end
    class AbilityParseTree < Struct.new(:name, :parameters); end
    class AbilityParse
      # we may end up never using this but it is nifty.
      # Build an ability definition from a syntax summary string
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
        begin
          parameters = AssociativeArray.new.no_clobber.require_key
          name = nil
          catch :end_of_string do
            name = parse_off_name eat_me
            parse_off_params Cli::SwitchParameter,   eat_me, parameters
            parse_off_params RequiredParameter, eat_me, parameters
            parse_off_params OptionalParameter, eat_me, parameters
          end
          raise Error.new("I don't know what to do with this") if
            eat_me.length > 0
          return AbilityParseTree.new(name, parameters)
        rescue Error => e
          e.context(string, @offset)
          raise e
        end
      end
      def parse_off_name string
        md = Ability::NameRe.match(string)
        raise Error.new("expecting valid name") unless md
        @offset += md[1].length
        string.slice!(0,md[1].length)
        md[1].strip
      end
      def parse_off_params type, string, assoc_array
        re = type.const_get 'CliRegexp'
        while (md = re.match(string))
          parameter = ParameterDefinition.from_parse(md, type)
          assoc_array[parameter.name] = parameter
          @offset += md[0].length
          string.slice!(0,md[0].length)
        end
        throw :end_of_string if ""==string
      end
    end
    module SwitchParameter
      include Defaultable
      ShortRe   = /^-(.+)$/
      LongRe    = /^--(.+)$/
      ArgNameRe = /^ *\[?([^\]]+)\]?$/
      NoStyleRe = /^\[no-\](.+)/
      CliRegexp =
        %r{\A [[:space:]]*
        \[-
          (?:
            ([-a-z])
            |
            -(?:
              ([a-z0-9][-a-z0-9]+)
              |
              ([a-z0-9]*[-a-z0-9]*)\[([a-z0-9])\]([-a-z0-9]*)
            )
          )
          (?:
            (?:[[:space:]]|=)
            <([a-z_][-a-z0-9_]*)>
            |
            [[:space:]]*
            \[
              (?:[[:space:]]|=)
              <([a-z_][-a-zA-Z0-9]*)>
            \]
          )?
        \]
        [[:space:]]*
      }mix
      attr_reader :short, :long, :argument_name, :many, :no_style
      attr_accessor :many
      alias_method :many?, :many
      alias_method :no_style?, :no_style
      def cli_unparse
        '['+[ (@short[0] && "-#{@short[0]}") || (@long[0] && "--#{@long[0]}"),
        takes_argument? ? argument_required? ? "<#{@argument_name}>" :
          "[#{@argument_name}]" : nil ].compact * ' ' + ']'
      end
      def name
        @long.length > 0 ? (@no_style ? yes_style : @long[0]): @short[0]
      end
      def name_as_switch
        @long.length > 0 ? (@no_style ? "--#{yes_style}" : "--#{@long[0]}"):
          ( @short.length > 0 ? "-#{@short[0]}" : nil )
      end
      def yes_style
        mds = @long.map{|x| NoStyleRe.match(x) }.compact
        mds.size > 0 and "#{mds[0][1]}"
      end
      def takes_argument?;  !! @argument_name end
      def default_defined?; instance_variable_defined? '@default' end
      alias_method :inspect, :cli_unparse
      alias_method :to_s, :cli_unparse
      Options = {:many=>true, :default=>true}
      def init_from_optparse_switch switch, opts=nil
        opts ||= {}
        @optparse_switch = switch
        @cli_type = :switch
        @required = false
        @short = @optparse_switch.short.map{|x| ShortRe.match(x).captures[0] }
        @long = @optparse_switch.long.map{|x| LongRe.match(x).captures[0] }
        @no_style = !! @long.detect{|x| NoStyleRe =~ x }
        arg_name = nil
        if @optparse_switch.arg
          arg_name = (md = ArgNameRe.match(@optparse_switch.arg) and md[1] )
          arg_name ||= @optparse_switch.arg.strip
        end
        @argument_name = arg_name
        case @optparse_switch
        when OptionParser::Switch::NoArgument
          # rien
        when OptionParser::Switch::OptionalArgument
          @argument_required = false
        when OptionParser::Switch::RequiredArgument
          @argument_required = true
        when OptionParser::Switch::PlacedArgument # @todo what is difference?
          @argument_required = true
        else raise RutimeError.new(
          "Unhandled case: #{@optparse_switch.class}")
        end
        opts.each do |key,value|
          raise ArgumentError("invalid option for switch: #{key}") unless
            Options[key]
          self.send("#{key}=", value)
        end
      end
      def default= mixed
        raise ArgumentError.new("For now, default arguments must be Strings"<<
        " not #{mixed.inspect}, because they are run thru the OptionParser"<<
        " (for #{self.name_as_switch})") unless mixed.kind_of?(String)
        # no special handling for no_style options
        @default = mixed
      end
    end

    module Run
      # this gets mixed in to the implementor to give it cli_run
      def cli_run argv
        # @todo currently no support for object-level inteface objects
        interface = self.class.interface
        request = RequestLite.new argv
        request = interface.default_request if request.empty?
        return ResponseLite.new(:error=>"empty request")  if request.empty?
        # @todo don't change default object -- maybe dup it?
        request.unparsed_parameters = [] if (request.unparsed_parameters.nil?)
        name = request.name
        ability = interface.abilities.detect{|x| x.name == name} or
          return ResponseLite.new(:error=>
            %{don't know how to respond to "#{request.name}"})
        method_name = ability.method_name
        return interface.on_method_missing(self, ability, request) unless
          respond_to? method_name
        begin
          early_exit = catch(:cli_early_exit) do
            Cli::RequestParse.parse_request! ability, request
          end and return early_exit
        rescue ApplicationArgumentError => e
          return ResponseLite.new(:error=>e.to_s, :original_exception=>e)
        end
        args = request.parsed_parameters
        arity = self.method(method_name).arity
        raise ArgumentError.new("expecting #{self.class}##{method} "<<
          "to take #{args.size} arguments per the definition.  "<<
          "Its arity is #{arity}.") if
          ( (arity > 0 && arity != args.length) ||
            (arity < 0 && arity.abs < (args.length - 1) ) )
        send(method_name, *args)
      end
    end
    module DefaultImplementations
      def self.help(impementing_object,interface,ability,request)
        # flagrant hack again
        optparse = OptionParser.new
        class << optparse;
          attr_accessor :stack
          def last; @stack[2].instance_variable_get('@list').last end
        end
        optparse.banner = "usage: #{optparse.program_name} <command> "<<
        " [options]"
        optparse.separator ' '
        optparse.separator 'available commands:'
        interface.abilities.each do |ability|
          optparse.on("--#{ability.name}", *ability.desc)
          switch = optparse.last
          switch.instance_variable_set('@long',[ability.name])
        end
        ResponseLite.new(:message => optparse.to_s)
      end
      def self.version(impementing_object,interface,ability,request)

      end
    end
  end

  class ParameterDefinition
    attr_reader :argument_required, :cli_type, :optparse_switch
    alias_method :argument_required?, :argument_required

    def self.from_optparse_switch switch, opts
      pd = self.new
      pd.extend Cli::SwitchParameter
      pd.init_from_optparse_switch switch, opts
      pd
    end
    def self.from_parse md, type
      pd = self.new
      pd.init_from_parse(md,type)
      pd
    end
    def init_from_parse  md, type
      case true
      when type == Cli::SwitchParameter
        extend Cli::SwitchParameter
        @cli_type = :switch
        @required = false
        @short = [md[1] || md[4]]
        @long = [md[2] || "#{md[3]}#{md[4]}#{md[5]}"]
        @argument_name = md[6] || md[7]
        if @argument_name
          @argument_required = ! md[7]
        end
        @short.compact!
        @long.reject!{|x| x==""}
      when type == RequiredParameter
        extend RequiredParameter
        @cli_type = :required
        @required = true
        @argument_required = true
        @name = md[1]
      when type == OptionalParameter
        extend OptionalParameter
        @cli_type = :optional
        @required = false
        @argument_required = true
        @name = md[1]
      else
        raise ArgumentError.new "bad type: #{type.inspect}"
      end
    end
    alias_method :subset_before_cli?, :subset?
    # for a parameter definition to be a subset of another paramter definition
    # it must define everything that the other one does, and possibly more
    # Note that because a definition is usually subtractive,
    # it can require more information to define a smaller set.
    # The set of all peple matching the description
    # "a boy" is larger than the set of all people matching the description
    # "a boy named sue", and the latter description requires more information.
    # warning! this isn't perfect. this will return false positives for some
    # optparse switches b/c we don't bother checking all its properties
    def subset? other
      return false unless subset_before_cli? other
      i_am_subset = true;
      [:argument_required?, :cli_type].each do |aspect|
        unless other.send(aspect).nil?
          if send(aspect) != other.send(aspect)
            i_am_subset = false
            break
          end
        end
      end
      i_am_subset
    end
  end
end
