# this was started before i discovered http://www.deveiate.org/projects/Linguistics/
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
          flatten.join(' ')+'.'
        end
      end
    

      class Np
        include Phrase
        attr_reader :plurality, :article
        attr_accessor :say_count, :list
        def say_count
          @say_count or @list.size <= 1          
        end
        def flatten_into(arr)
          arr << article if(@say_count || @list.size < 2)
          @adjp.flatten_into(arr) if @adjp
          arr << @root + (plurality == :singular ? '' : 's')
          @pp.flatten_into(arr) if @pp
          flatten_list_into(arr) if say_count and @list.size>0
        end
        def flatten_list_into(arr)
          if (@list.size>0) 
            arr.last << ':' unless arr.last =~ /:$/  # hack
            arr << @list.and{|x|%{"#{x}"}}
          end
        end
        def article
          case list.size
          when 0 then 'no'
          when 1 then 'only one'
          when 2 then 'two'
          else list.size.to_s
          end          
        end
        def list=(arr)
          @list = arr
          @list.extend List unless @list.kind_of? List
        end
        def plurality
          @list.size == 1 ? :singular : :plural          
        end
        def self.[](*args)
          self.new(args)
        end
        def initialize(args)
          @say_count = true          
          args.each do |arg|
            case arg
            when String
              @root = arg
            when Adjp
              @adjp = arg
            when Pp
              @pp = arg
            else
              raise %{no: "#{arg.class}" -- "#{arg}"}
            end
          end
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
  end # Lingual
end