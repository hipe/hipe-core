# bacon spec/loquacious/spec_kind-of.rb
# bacon spec/infrastructure/spec_strict-attr-accessor.rb
module Hipe
  module Loquacious
    class KindOf
      def initialize(klass_or_module)
        unless (klass_or_module.kind_of? Module)
          raise TypeError.new self.class.new(Module).excludes?(klass_or_module)
        end
        @module = klass_or_module
      end
      def excludes?(thing)
        unless (thing.kind_of? @module)
          "expecting #{@module} had #{thing.class}"
        end
      end
    end
  end
end
