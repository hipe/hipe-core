# this was started before i discovered http://www.deveiate.org/projects/Linguistics/
# indeed i continued to work on it after i discoverd the above link, which i haven't looked at yet.
require 'hipe-core' # for exceptions
require 'hipe-core/struct/open-struct-write-once-extension'

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
      
      class Rules
        @loaded = nil
        def self.exist!
          return @loaded unless @loaded.nil?
          rs = Gem.source_index.search(Gem::Dependency.new('rools', Gem::Version.new('0.4')))
          return @loaded unless @loaded = rs.count > 0
          require 'rools'; require 'logger'          
          ::Rools::Facts.send(:define_method,:value){
            if @fact_value.respond_to?(:size) && @fact_value.respond_to?(:[]) && @fact_value.size == 1
              @fact_value[0]
            else
              @fact_value
            end
          }
        end
        def self.log=(b)
          return unless exist!
          ::Rools::Base.logger = b ? ::Logger.new($stdout) : nil
        end
        def self.quantity_rules
          return unless exist!
          self.log=true
          @quantity ||= ::Rools::RuleSet.new do
             rule '"a/an"' do
               #parameter IndefiniteArticle
               condition{ np.size == 1 }
               consequence{ result.article = /^[aeiou]/ =~ np.first_token ? 'an' : 'a' }
             end
            
            
            #rule '"no"' do
            #  parameter Np
            #  condition{ artp.np.size == 0 };
            #  consequence { artp.surface = 'no' }
            #end
            #rule '"a couple of"' do
            #  parameter IndefiniteArticle
            #  condition{ artp.np.size == 2 }
            #  consequence { artp.surface = 'a couple of' }
            #end
            #rule '"some"' do
            #  parameter IndefiniteArticle
            #  condition{ artp.np.size > 2 }
            #  consequence { artp.surface = 'some' }
            #end
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
          @parts = parts
          @parts.each{|x| if x.kind_of?(String) then x.extend(Token) end }
        end

        def say
          flatten(arr=[])
          arr.compact!
          case arr.size
          when 0 then ''
          when 1 then arr[0]
          else # join was so much prettier but we needed punct hack (for colons)
            str = arr[0]
            (1..arr.size-1).each do |idx|   # (this won't iterate for (1..0)
              str << ' ' unless arr[idx].kind_of? Punct
              str << arr[idx].to_s
            end
            str
          end
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
              raise %{Invalid element to build a sentence phrase #{arg.inspect}}
            end
          end
        end
        def flatten(arr)
          @vp = ToBe.new()
          @vp.agent = @np
          if (@np.say_count || @np.say_count.nil?)
            arr << 'there'
            @vp.flatten(arr)
            @np.flatten(arr)
          else
            @np.flatten(arr)
            @vp.flatten(arr)
            @np.flatten_list_into(arr)
          end
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
          o = OpenStructWriteOnceExtension.new()          
          o.write_once!(*(them=[:adjp, :artp, :list, :pp, :root, :size]))
          args.each do |arg|
            case arg
            when Fixnum   then o.size = arg
            when String   then o.root = arg
            when Adjp     then o.adjp = arg
            when Pp       then o.pp   = arg
            when Array    then o.list = arg
            when Artp     then o.artp = arg
            when Symbol  
              rs = 
              o.artp = En.artp(case arg
                when :the   then :def
                when :an,:a then :indef
                else raise e("no") end)
            else
              raise e(%{can't determine part of speec from #{arg.inspect}})
            end
          end
          raise e(%{can't have both size and list}) if o.size and o.list
          them.each{|it| instance_variable_set %{@#{it}}, o.send(it)}
        end        
        def size
          @size or ( @list && @list.size ) or nil
        end 
        def flatten(array)
          arr = []   #indef article must agree w/ whatever comes first in this array
          @adjp.flatten(arr) if @adjp
          arr << @root + (plurality == :singular ? '' : 's')
          @pp.flatten(arr) if @pp
          if r = Rules.quantity_rules
            o = OpenStruct.new(
              :list        => @list,         
              :artp        => @artp || En.artp(:indef),
              :say_count   => @say_count || true,
              :size        => size || 1,
              :first_token => arr[0],
              :result      => OpenStruct.new
            )
            while (:again == catch(:try) do  
              raise e("failure is not an option") if :fail == r.assert(o.artp)
            end ) do; end # loop it when necessary            
            debugger
            'x'
          end
          array.concat arr
          array
        end
        def list=(arr)
          @list = arr
          @size = nil
          @list.extend List unless List === @list
        end
        def plurality
          size == 1 ? :singular : :plural
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
