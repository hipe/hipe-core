require 'optparse'
module Hipe::Interfacey
  class Ability
    def self.from_string string
      p = Cli::AbilityParse.new
      def_struct = p.parse string
      return new(def_struct.name, def_struct.parameters)
    end
  end
  module Cli
    class AbilityParseTree < Struct.new(:name, :parameters); end
    class AbilityParse
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
          parameters = AssociativeArray.new
          parameters.no_clobber
          name = nil
          catch :end_of_string do
            name = parse_off_name eat_me
            parse_off Cli::SwitchParameter,   eat_me, parameters
            parse_off Cli::RequiredParameter, eat_me, parameters
            parse_off Cli::OptionalParameter, eat_me, parameters
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
      def parse_off type, string, assoc_array
        re = type.const_get 'Regexp'
        while (md = re.match(string))
          parameter = ParameterDefinition.from_cli_parse(md, type)
          assoc_array[parameter.name] = parameter
          @offset += md[0].length
          string.slice!(0,md[0].length)
        end
        throw :end_of_string if ""==string
      end
    end
    module SwitchParameter
      Regexp =
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
      attr_reader :short, :long, :argument_name
      def unparse
        '['+[ (@short[0] && "-#{@short[0]}") || (@long[0] && "--#{@long[0]}"),
        takes_argument? ? argument_required? ? "<#{@argument_name}>" :
          "[#{@argument_name}]" : nil ].compact * ' ' + ']'
      end
      def name
        @long.length > 0 ? @long[0] : @short[0]
      end
      def takes_argument?
        !! @argument_name
      end
      alias_method :inspect, :unparse
      alias_method :to_s, :unparse
    end
    module RequiredParameter
      Regexp = %r{^[[:space:]]*<([_a-z][-_a-z0-9]*)>[[:space:]]*}
      def name; @parameter_name end
      def unparse; "<#{@parameter_name}>" end
      alias_method :inspect, :unparse
      alias_method :to_s, :unparse
    end
    module OptionalParameter
      Regexp = %r{^[[:space:]]*\[<([_a-z][-_a-z0-9]*)>\][[:space:]]*}
      def name; @parameter_name end
      def unparse; "[<#{@parameter_name}>]" end
      alias_method :inspect, :unparse
      alias_method :to_s, :unparse
    end
  end
  class ParameterDefinition
    attr_reader :argument_required, :parameter_required, :cli_type
    alias_method :argument_required?, :argument_required
    def self.from_cli_parse md, type
      pd = self.new
      pd.init_from_cli_parse(md,type)
      pd
    end
    def init_from_cli_parse  md, type
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
      when type == Cli::RequiredParameter
        extend Cli::RequiredParameter
        @cli_type = :required
        @required = true
        @argument_required = true
        @parameter_name = md[1]
      when type == Cli::OptionalParameter
        extend Cli::OptionalParameter
        @cli_type = :optional
        @required = false
        @argument_required = true
        @parameter_name = md[1]
      else
        raise ArgumentError.new "bad type: #{type.inspect}"
      end
    end
  end
end
