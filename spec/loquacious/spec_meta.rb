# bacon tmp.rb
require 'ruby-debug'
require 'bacon'

module Test1

  module DefaultMethodSet
    def self.extend_object klass
    end
    def alpha
      "hi i'm alpha"
    end
  end

  class Tiger
    extend DefaultMethodSet
  end

  describe DefaultMethodSet do
    it "extend_object() will swallow calls to extend()" do
      Tiger.methods.grep(/^alpha$/).size.should.equal 0
    end
  end

end

module Test2

  module ClassExtender
    def extend_object klass
      super
    end
  end

  module DefaultMethodSet
    extend ClassExtender
    def alpha
      "hi i'm alpha"
    end
  end

  module ExtendedMethodSet
    extend ClassExtender
    include DefaultMethodSet
  end

  class Tiger
    extend ExtendedMethodSet
  end

  describe DefaultMethodSet do
    it "you can get something like inheirtance this way" do
      Tiger.methods.grep(/alpha/).size.should.equal 1
    end
  end

end

# bacon tmp.rb
require 'ruby-debug'

module Test3
  module InstanceMethods
    def inst_meth_1
      "i'm the one"
    end
  end

  module ClassMethodsPlusInstanceMethods
    def extend_object klass
      super
      klass.instance_eval do
        include InstanceMethods
      end
    end
  end

  module DefaultMethodSet
    extend ClassMethodsPlusInstanceMethods
    def alpha
      "hi i'm alpha"
    end
  end

  module ExtendedMethodSet
    extend ClassMethodsPlusInstanceMethods
    include DefaultMethodSet
  end

  class Tiger
    extend ExtendedMethodSet
  end

  describe self do
    it "should do the hack with instance methods" do
      Tiger.instance_methods.grep(/^inst_meth_1$/).size.should.equal 1
    end
  end
end
