require 'hipe-core/lingual/en'
module Hipe
  module Loquacious
    module EnumLike
      include Hipe::Lingual::English

      def self.[](array)
        array.extend self
        array.init_as_enum_like
        array
      end

      def init_as_enum_like
        throw TypeError.new("need array had #{array.inspect}") unless self.kind_of? Array
      end

      def excludes?(value)
        if include? value
          false
        else
          say(value)
        end
      end

      def say(value)
        the_list = self
        %{Expecting } << en{ list(the_list.map{|x| x.inspect}) }.either() << ".  Had #{value.inspect}."
      end
    end
    #class Enum < Array
    #  include EnumLike
    #  def initialize()
    #    init_as_enum_like
    #  end
    #  def ===(thing)
    #    include? thing
    #  end
    #end
  end
end
