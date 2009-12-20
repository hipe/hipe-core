require 'hipe-core'
require 'orderedhash'
require 'hipe-core/struct/hash-like-write-once-extension'

module Hipe
  class RulesLite
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
    def assert(hash)
      raise e(%{Rules assert must take a hash-like object, not #{hash}}) unless
        (hash.respond_to?(:[]) and hash.respond_to?(:keys))
      context = EvaluationContext.new(hash)
      @rules.each do |name, rule|
        if context.instance_eval(&rule.condition)
          rs = context.instance_eval(&rule.consequence)
          return rs
        end
      end
      nil
    end
    class Rule
      include Common
      attr_reader :condition
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
      def initialize(hash)
        @hash = hash
        meta = class << self; self; end
        hash.each do |key,value|
          raise e(%{keys must be valid method names, not #{key.inspect}}) unless
            /^[_a-zA-Z][a-zA-Z0-9_]*$/ =~ key.to_s
          meta.send(:define_method, key.to_s) { hash[key] }
        end
      end
      def has?(key)
        @has.key_exists?(key)
      end
    end
  end
end
