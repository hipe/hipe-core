# this was started before i discovered http://www.deveiate.org/projects/Linguistics/
# indeed i continued to work on it after i discoverd the above link, which i haven't looked at yet.
require 'hipe-core' # for exceptions
require 'hipe-core/struct/open-struct-common-extension'
require 'hipe-core/struct/open-struct-write-once-extension'
require 'hipe-core/logic/rules-lite'

module Hipe
  module Lingual

    def self.en(&block)
      En.construct(&block)
    end

    # just for modules to pull in the "en()" constructor
    # WARNING this is experimental and the exact name and means of extending it may change
    module English
      def en &block
        En.construct(&block)
      end
    end

    module En
      def en &block
        En.construct(&block)
      end


      def self.sp   *args; Sp[*args] end
      def self.np   *args; Np[*args] end
      def self.pp   *args; Pp[*args] end
      def self.adjp *args; Adjp[*args] end
      def self.artp *args; Artp[*args] end
      def self.outs; @outs ||= [] end
      def self.list(items)
        List[items]
      end
      def self.construct &block
        phrase = self.instance_eval(&block)
        phrase.outs.concat(@outs) if (@outs)
        phrase
      end

      SentenceRules = Hipe::RulesLite.new do
        rule 'if article is not definite and count is known and sayable (or zero or one), say "there is/are..."' do
          condition{
            zero_or_one = (np.size==0 or np.size==1)

            (!(DefiniteArticle===np.artp) or zero_or_one) and  np.size and
            ((np.say_count or np.say_count.nil?) or (zero_or_one) )
          }
          consequence {
            tokens << 'there'
            vp.flatten(tokens)
            np.flatten(tokens)
          }
        end

        rule 'else do  ...' do
          condition{ true }
          consequence do
            np.flatten(tokens)
            vp.flatten(tokens)
            apply AricleAndCountRules.rules['# list'] if np.list
          end
        end
      end

      AricleAndCountRules = Hipe::RulesLite.new do
        rule "if count is known and sayable (or zero), say..." do
          condition{ size and ((say_count.nil? or say_count) or (size==0 or size==1))}
          consequence{
            if (IndefiniteArticle===artp)
              apply '# indef article casual count'
            else
              apply '# count'
            end
            tokens.unshift('the') if ( DefiniteArticle===artp and size != 0)
            apply '# list' if list
          }
        end

        rule "if count is not sayable..." do
          condition{ say_count==false }
          consequence{
            tokens.unshift('the') if DefiniteArticle === artp
          }
        end

        # many other rules were in 28c36c45705610165e427d1d4fa5448722fdf837

        rule '# count' do
          consequence do
            tokens.unshift(['no','one','two','three'][np.size] || np.size.to_s)
          end
        end

        rule '# list' do
          consequence do
            if (np.list.size > 0)
              if (np.list.size > 0)
                tokens << Punct[':']        # colon
              end
              tokens << np.list.and()
            end
          end
        end

        rule '# indef article casual count' do
          consequence do
            if (np.size==1)
              tokens.unshift((tokens[0] =~ /^[aeiou]/i) ? 'an' : 'a')
            else
              tokens.unshift ['no',nil,'a couple of','a few','some','several'][np.size] || 'a lot of'
            end
          end
        end
      end

      module Phrase
        # the most ridiculous factory you've ever made
        module ClassMethods
          def [](*parts)
            return self.new(parts)
          end
        end

        def self.included(obj)
          obj.extend ClassMethods
          super(obj)
        end

        def initialize(parts)
          @outs = nil
          @parts = parts
          @parts.each{|x| if x.kind_of?(String) then x.extend(Token) end }
        end

        # multiplex the output stream. (if you want to see what these guys are saying during testing.)
        #
        #     sp.out << $stdout   # during tests to hear what they are saying
        #
        # @return an array of output streams
        def outs
          @outs ||= []
        end

        def say
          flatten(arr=[])
          arr.compact!
          ret = case arr.size
            when 0 then ''
            when 1 then arr[0]
            else # join was so much prettier but we needed punct hack2 (for colons)
              str = arr[0]
              (1..arr.size-1).each do |idx|   # (this won't iterate for (1..0)
                str << ' ' unless arr[idx].kind_of? Punct
                str << arr[idx].to_s
              end
              str
            end
          if (@outs)
            @outs.each{|out| out.write ret }
          end
          ret
        end

        def flatten(arr)
          all_my_children{|child| child.flatten(arr)}
          arr
        end

        def token_count
          sum = 0
          all_my_children{|x| sum += x.token_count}
          sum
        end

        def all_my_children &block
          @parts.each(&block)
        end

        def e(*args)
          Hipe::Exception[*args]
        end
      end

      module Token
        include Phrase
        def token_count; 1 end
        def flatten(arr); arr << self; arr; end
      end

      class Sp
        include Phrase
        attr_accessor :np, :vp
        def initialize(args)
          args.each do |arg|
            case arg
            when Np
              @np = arg
            else
              raise e(%{Invalid element to build a sentence phrase #{arg.inspect}})
            end
          end
        end
        def flatten(arr)
          @vp = ToBe.new()  # hack4 - no verbs yet
          @vp.agent = @np
          SentenceRules.assess({:tokens => arr, :vp => @vp, :np => @np, :list=>@np.list})
          arr
        end
      end
      class Punct < String
        def self.[](thing)
          return self.new(thing)
        end
        def initialize(thing)
          replace(thing)
        end
      end
      class Np
        include Phrase
        attr_reader :plurality, :article, :tokens
        attr_accessor :list, :artp, :say_count
        def initialize(args)
          @say_count = nil
          if (Hash === args.last)
            opts = args.pop
            @say_count = opts[:say_count]
          end
          o = OpenStructCommonExtension[OpenStructWriteOnceExtension.new()]
          them = them=[:adjp, :artp, :list, :pp, :root, :size]
          o.write_once!(*them)
          begin
            arg = nil
            args.each do |arg|
              case arg
              when Fixnum   then o.size = arg
              when String   then o.root = arg
              when Adjp     then o.adjp = arg
              when Pp       then o.pp   = arg
              when Array    then o.list = List[arg]
              when Artp     then o.artp = arg
              when Symbol
                rs =
                o.artp = En.artp(case arg
                  when :the   then :def
                  when :an,:a then :indef
                  else raise e("no") end)
              else
                raise e(%{can't determine part of speech from #{arg.inspect}})
              end
            end
          rescue TypeError => e
            if e.message.match(%r{can't write to frozen index "([^"]+)"})
              msg = <<-HERE.gsub(/^#{' '*14}/,'').gsub(/\n/,' ')
              Sorry, a noun phrase can only have one #{$1}.  (Classes
              map to noun phrase parts and a noun phrase can only have one of each type.  )
              Your value for "#{$1}" (#{arg.inspect}) matched an existing value
              (#{o[$1.to_sym].inspect}).
              Your arg types were: [#{args.map{|x| x.class.to_s} * ', '}].
              Your arg values were: [#{args.map{|x| x.inspect} * ', '}]
              HERE
              raise self.e(msg)
            else
              raise e
            end
          end
          raise e(%{can't have both size and list}) if o.size and o.list
          them.each{|it| instance_variable_set %{@#{it}}, o.send(it)}
        end
        def say_list
          true
        end
        def size
          @size or ( @list && @list.size ) or nil
        end
        def size=(size)
          raise TypeError(%{must be Fixnum not #{size.inspect}}) unless Fixnum === size
          raise TypeError(%{can't set size when list exists}) if @list
          @size = size
        end
        def flatten(array)
          arr = []   #indef article must agree w/ whatever comes first in this array
          @adjp.flatten(arr) if @adjp
          arr << @root + (plurality == :plural ? 's' : '')
          @pp.flatten(arr) if @pp
          AricleAndCountRules.assess(  :tokens    => arr,       :artp => artp,   :np    => self,
            :say_list => say_list,    :say_count => say_count, :list => list,   :size  => size
          )
          array.concat arr
          array
        end
        def list=(arr)
          @list = arr
          @size = nil
          @list.extend List unless List === @list
        end
        def plurality
          size.nil? ? nil : ( size == 1 ? :singular : :plural )
        end
      end

      class Vp
        include Phrase
      end

      class ToBe < Vp
        attr_accessor :agent
        def initialize(); end
        def flatten(arr)
          arr << ( @agent.plurality == :singular ? 'is' : 'are' )
          arr
        end
      end

      class Pp
        include Phrase
      end

      class Adjp
        include Phrase
      end

      module IndefiniteArticle; end
      module DefiniteArticle; end

      # manage agreement with noun phraes (a/an) and agreement with count (this/these)
      class Artp
        attr_accessor :np, :type
        include Phrase
        def initialize(args)
          raise ArgumentError.new("wrong number of arguments (#{args.size} for 1)") unless args.size == 1
          type = args[0]
          @type = case type
          when :def then self.extend DefiniteArticle; :def
          when :indef then self.extend IndefiniteArticle; :indef
          else raise e(%{sorry, bad article type: "#{type.inspect}"})
          end
        end
      end

      module List
        def self.[](array)
          array.extend self
          array
        end
        def self.join list, conj1, conj2, &block
          list = list.map(&block) if block
          case list.size
          when 0 then 'nothing'
          when 1 then list[0]
          else
            joiners = ['',conj2]
            joiners += ::Array.new(list.size-2,conj1) if list.size >= 3
            list.zip(joiners.reverse).flatten.join
          end
        end

        def either &block
          (self.size > 1 ? "either " : '')+ self.or(&block)
        end

        def or &block
          Hipe::Lingual::List.join self, ', ', ' or ', &block
        end

        def and &block
          Hipe::Lingual::List.join self, ', ', ' and ', &block
        end
      end

      module Helpers
        SEC_PER_MIN = 60
        SEC_PER_HOUR = SEC_PER_MIN * 60
        SEC_PER_DAY = SEC_PER_HOUR * 24
        SEC_PER_WEEK = SEC_PER_DAY * 7
        SEC_PER_MONTH = SEC_PER_WEEK * 4

        # action_view was too heavy to pull in just for this
        def time_ago_in_words(t)
          seconds_ago = (Time.now - t)
          in_future = seconds_ago <= 0
          distance = seconds_ago.abs
          amt, unit, fmt = case distance
            when (0..SEC_PER_MIN)              then [distance,              'second', '%.0f']
            when (SEC_PER_MIN..SEC_PER_HOUR)   then [distance/SEC_PER_MIN,  'minute', '%.1f']
            when (SEC_PER_HOUR..SEC_PER_DAY)   then [distance/SEC_PER_HOUR, 'hour',   '%.1f']
            when (SEC_PER_DAY..SEC_PER_WEEK)   then [distance/SEC_PER_DAY,  'day',    '%.1f']
            else                                    [distance/SEC_PER_WEEK, 'week',   '%.1f']
          end
          number = ((amt.round - amt).abs < 0.1) ? amt.round : fmt.t(amt)
          noun =  ('1' == number.to_s) ? unit : unit.pluralize
          %{#{number} #{noun} #{in_future ? 'from now' : 'ago'}}
        end

      end # Helpers
    end # En
    List = En::List
    def self.list(array)
      return List[array]
    end
  end # Lingual
end
