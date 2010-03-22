require 'ruby-debug'
require 'hipe-core/struct/ass-arr'

module Hipe
  class RulesLite
    module Fail; end
    class RuntimeError < RuntimeError
      include Fail
    end
    module CommonInstanceMethods
      def flail msg
        raise RuntimeError.new msg
      end
      def meta
        class << self; self end
      end
      def def! name_str, value
        meta.send(:define_method, name_str) { value }
      end
      def quacks_like_hash? mixed
        mixed.respond_to?(:[]) and mixed.respond_to?(:keys)
      end
    end
    include CommonInstanceMethods
    attr_reader :rules
    def initialize(&block)
      @rules = AssArr.new
      rules.on_clobber do |arr, key, value|
        flail(
          "sorry, cannot redefine #{key.inspect} without} "<<
          "removing it first (not implemented)}"
        )
      end
      instance_eval(&block)
    end
    def rule name, &block
      rules.push_with_key Rule.new(name,&block), name
    end
    # @return the first Rule that matched or nil
    def assess hash
      raise TypeError.new(
        "RulesLite#apply must take a hash-like object, not "<<
        "#{hash}"
        ) unless quacks_like_hash?(hash)
      context = EvaluationContext.new hash, @rules
      result = nil
      begin
        loop_result = catch(:stop_loop) do
          rules.each_with_key do |rule, name|
            next unless rule.condition
            context.rule = rule
            if context.instance_eval(&rule.condition)
              result = context.run(rule.consequence)
              break
            end
          end
        end
      end while (loop_result && loop_result[:because] == :re_evaluate )
      result
    end
    class Rule
      include CommonInstanceMethods
      attr_reader :condition
      attr_reader :name
      def initialize(name,&block)
        @name = name
        @condition = nil
        @consequence = nil
        instance_eval(&block)
      end
      def condition(&block)
        return @condition if block.nil? # pretty terrible
        flail("can only have one condition per rule") if @condition
        @condition = block
      end
      def consequence(&block)
        return @consequence if block.nil? # bad
        flail("can only have one consequence per rule") if @consequence
        @consequence = block
      end
    end
    class EvaluationContext
      include CommonInstanceMethods
      attr_reader :rules
      attr_accessor :rule
      def initialize hash, rules
        @reevaluated_from = {}
        @rules = rules
        @hash = hash
        meta = class << self; self; end
        hash.each do |key,value|
          flail("keys must be valid method names, not #{key.inspect}}") unless
            /^[_a-zA-Z][a-zA-Z0-9_]*$/ =~ key.to_s
          def! key.to_s, hash[key]
        end
      end
      def has? key
        @hash.key? key
      end
      def run consequence
        instance_eval(&consequence)
      end
      # Apply the consequence of the rule w/o evaluating the conditions!
      #
      def apply rule
        run((String===rule) ? @rules[rule].consequence : rule.consequence)
      end
      def reevaluate
        throw(:stop_loop, :because=>:avoid_infinite_loop) if
          @reevaluated_from[rule.name]
        @reevaluated_from[rule.name] = true
        throw(:stop_loop, :because=>:re_evaluate)
      end
    end
  end
end
