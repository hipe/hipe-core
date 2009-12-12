module Hipe
  module Reflection
    def self.local_instance_methods(obj)            
      klass = (obj.class == Class ? obj : obj.class)
      anc = klass.ancestors
      methods_from_parents = anc.slice(1,anc.size).inject([]){|acc,val| acc |= val.instance_methods}
      my_methods = klass.instance_methods - methods_from_parents
      return
    end
  end
end
