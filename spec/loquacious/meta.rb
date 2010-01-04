#!/usr/bin/env ruby
require 'ruby-debug'

MethodsToAdd = {
  :alpha => lambda{ 'i am alpha' },
  :beta => lambda{ 'i am beta' }
}

module DefaultMethods
end

module CoolThing
  def self.included thing
    (class << thing; self end).instance_eval{ include CoolThing.module }
  end
  def self.module
    @default ||= begin
      MethodsToAdd.each do |x,y|
        DefaultMethods.module_eval{ define_method(x, &y) }
      end
      DefaultMethods
    end
  end
end



class Tiger
  include CoolThing
end

class Tiger2
end

puts Tiger.alpha
