require 'hipe-core'
require 'orderedhash'
require 'hipe-core/struct/hash-like-write-once-extension'

module Hipe
  class RulesLite
    attr_reader :rules
    module Common
      def e(*args); Hipe::Exception[*args] end
    end
    include Common
    def initialize(&block)
      @rules = HashLikeWriteOnceExtension[OrderedHash.new]
      rules_lite_obj = self
      @rules.write_once!{|rule_name,rule_value| raise rules_lite_obj.e(
        %{sorry, cannot redefine #{rule_name.inspect} without removing it first (not implemented)}
      )}
      instance_eval(&block)
    end
    def rule (name,&block)
      @rules[name] = Rule.new(name,&block)
    end
    # @return the first Rule that matched or nil
    def assess(hash)
      raise TypeError.new(%{RulesLite#apply must take a hash-like object, not #{hash}}) unless
        (hash.respond_to?(:[]) and hash.respond_to?(:keys))
      context = EvaluationContext.new(hash,@rules)
      result = nil
      begin
        loop_result = catch(:stop_loop) do
          @rules.each do |name, rule|
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
      include Common
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
        raise e("can only have one condition per rule") if @condition
        @condition = block
      end
      def consequence(&block)
        return @consequence if block.nil? # bad
        raise e("can only have one consequence per rule") if @consequence
        @consequence = block
      end
    end
    class EvaluationContext
      attr_reader :rules
      attr_accessor :rule
      def initialize(hash, rules)
        @reevaluated_from = {}
        @rules = rules
        @hash = hash
        meta = class << self; self; end
        hash.each do |key,value|
          raise e(%{keys must be valid method names, not #{key.inspect}}) unless
            /^[_a-zA-Z][a-zA-Z0-9_]*$/ =~ key.to_s
          meta.send(:define_method, key.to_s) { hash[key] }
        end
      end
      def has?(key)
        @hash.key_exists?(key)
      end
      def run(consequence)
        instance_eval(&consequence)
      end
      # Apply the consequence of the rule w/o evaluating the conditions!
      #
      def apply(rule)
        run((String===rule) ? @rules[rule].consequence : rule.consequence)
      end
      def reevaluate()
        throw(:stop_loop, :because=>:avoid_infinite_loop) if @reevaluated_from[rule.name]
        @reevaluated_from[rule.name] = true
        throw(:stop_loop, :because=>:re_evaluate)
      end
    end
  end
end
