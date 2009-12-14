# this was started before i discovered http://www.deveiate.org/projects/Linguistics/
# indeed i continued to work on it after i discoverd the above link, which i haven't looked at yet.
module Hipe
  module Lingual

    def self.en(&block)
      En.construct(&block)
    end
        
    module En

      def self.sp   *args; Sp[*args] end
      def self.np   *args; Np[*args] end
      def self.pp   *args; Pp[*args] end
      def self.adjp *args; Adjp[*args] end
      def self.artp *args; Artp[*args] end
      def self.construct &block
        self.instance_eval(&block)
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
          @parts = parts
          @parts.each{|x| if x.kind_of?(String) then x.extend(Token) end }
        end

        def flatten
          self.flatten_into(arr=[])
          arr
        end

        # originally this was the domain of sentences only
        def say
          flatten.join(' ')
        end

        def flatten_into(arr)
          all_my_children{|child| child.flatten_into(arr)}
        end

        def token_count
          sum = 0
          all_my_children{sum += x.token_count}
          sum
        end

        def all_my_children &block
          @parts.each(&block)
        end
      end

      module Token
        include Phrase
        def token_count; 1 end
        def flatten_into(arr); arr << self end
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
              raise %{no: "#{arg.class}" -- "#{arg}"}
            end
          end
        end
        def flatten_into(arr)
          @vp = ToBe.new()
          @vp.agent = @np
          if (@np.say_count)
            arr << 'there'
            @vp.flatten_into(arr)
            @np.flatten_into(arr)
          else
            @np.flatten_into(arr)
            @vp.flatten_into(arr)
            @np.flatten_list_into(arr)
          end
        end
        def say
          flatten.join(' ') # Periods! punctuation! @todo  ("available subcommands are.")
        end
      end

      class Np
        include Phrase
        attr_reader :plurality, :article, :tokens
        attr_accessor :say_count, :list, :artp
        def initialize(args)
          @say_count = true
          if (Hash === args.last)
            opts = args.pop
            @say_count = opts[:say_count]
          end
          args.each do |arg|
            case arg
            when Fixnum   then @size = arg
            when String   then @root = arg
            when Adjp     then @adjp = arg
            when Pp       then @pp = arg
            when Array    then self.list = arg
            when Artp
              @artp = arg
              @artp.np = self
            when Symbol
              if (:the==arg) then @artp = En.adjp(:def)
              elsif (:an ==arg) then @artp = En.adjp(:indef)
              else; raise %{"no"} end
            else
              raise %{no: "#{arg.class}" -- "#{arg}"}
            end
          end
        end        
        def say_count
          @say_count or size <= 1
        end
        def size
          @size or @list.size
        end
        def flatten_into(arr)
          local_arr = []   # we do everything but article first to allow agreement!
          @adjp.flatten_into(local_arr) if @adjp
          local_arr << @root + (plurality == :singular ? '' : 's')
          @pp.flatten_into(local_arr) if @pp
          flatten_list_into(local_arr) if say_count and size>0 and @list
          @tokens = local_arr  #here is the thing -- this is just a hack to pass it to artp below
          if (@artp)
            @artp.flatten_into(arr)
          elsif(@say_count || size < 2)
            arr << article
          end
          local_arr.each do |x|
            arr << x # += won't work
          end
        end
        def flatten_list_into(arr)
          if (size>0 and @list)
            unless arr.last =~ /:$/ # colon hack
              if (@artp.nil? || @artp.is_a?(DefiniteArticle))
                arr.last << ':'
              end
            end
            arr << @list.and()  # {|x|%{"#{x}"}}
          end
        end
        def article
          case size
          when 0 then 'no'
          when 1 then 'one'
          when 2 then 'two'
          else size.to_s
          end
        end
        def list=(arr)
          @list = arr
          @size = nil
          @list.extend List unless @list.kind_of? List
        end
        def plurality
          size == 1 ? :singular : :plural
        end
        def self.[](*args)
          self.new(args)
        end
      end

      class Vp
        include Phrase
      end

      class ToBe < Vp
        attr_accessor :agent
        def initialize(); end
        def flatten_into(arr)
          arr << ( @agent.plurality == :singular ? 'is' : 'are' )
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
        attr_accessor :surface
        include Phrase
        def initialize(args)
          type = args[0]
          @type = case type
          when :def
            self.extend DefiniteArticle
            :def
          when :indef
            self.extend IndefiniteArticle
            :indef
          else
            raise Exception.new(%{sorry, bad article type: "#{type.inspect}"})
          end
          if (@has_rools.nil?)
            rs = Gem.source_index.search(Gem::Dependency.new('rools', Gem::Version.new('0.4')))
            @has_rools = (rs.count > 0)
            init_rules if @has_rools
          end
        end
        def init_rules
          @has_rools = true
          require 'rools'
          #require 'logger'; # Rools::Base.logger = Logger.new(STDOUT)
          @rules = Rools::RuleSet.new do
            rule 'the' do
              parameter DefiniteArticle
              consequence{
                hipe__lingual__en__artp.surface = (hipe__lingual__en__artp.np.size == 0) ? nil : 'the'
              }
            end
            rule 'no' do
              parameter Np
              condition{ article.np.count == 0 };
              consequence { hipe__lingual__en__artp.surface = 'no' }
            end
            rule 'a/an' do
              parameter IndefiniteArticle
              condition{ article.np.count == 1 }
              consequence{ hipe__lingual__en__artp.surface = (/^[aeiou]/ =~  np.tokens.first )? 'an' : 'a' }
            end
            rule 'a couple' do
              parameter IndefiniteArticle
              condition{ article.np.count == 2 }
              consequence { hipe__lingual__en__artp.surface = 'a couple' }
            end
            rule 'some' do
              parameter IndefiniteArticle
              condition{ article.np.count > 2 }
              consequence { hipe__lingual__en__artp.surface = 'some' }
            end
          end
        end
        attr_accessor :np
        def flatten_into(arr)
          return unless @rules
          pass_fail = @rules.assert(self)
          if(:pass == pass_fail)
            arr << self.surface
          else
            # debug this!
          end
        end
      end

      module List
        def self.[](array)
          array.extend self
          array
        end
        def self.join list, conj1, conj2, &block
          list.map!(&block) if block
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
    end # En
    List = En::List
    def self.list(array)
      return List[array]
    end
  end # Lingual
end
