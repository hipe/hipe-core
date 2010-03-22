module Hipe
  #
  # Really simple associative array with strictness.
  # The dozenth attept at this.
  #
  # F*ck OrderedHas_h, it's really long and does some evil
  #
  # This was born in the assess project.  Consider pushing changes here
  # to there.
  #
  # The philosophy here is it doesn't redefine any Array methods
  # (it just makes a lot of them protected.) So we don't get a nice []
  # accessor for accessing elements by their key.  Use at_key() for this.
  #
  class AssArr < Array

    #
    # make every array method protected except ones
    # that don't affect our @names property.
    #
    except = %w( [] size each inspect pretty_print )
    all = ancestors[1].instance_methods(false)
    these = all - except
    these.each do |name|
      protected name
    end
    def initialize()
      super()
      @names = {}
    end
    def push_with_key item, use_name
      if (use_name.nil? || use_name == '')
        fail "won't use empty or nil name: \"#{use_name.inspect}\""
      end
      if @names.include? use_name
        if @on_clobber
          return @on_clobber.call(self, use_name, item)
        else
          fail "already have \"#{use_name}\". use unset() first."
        end
      end
      next_index = length
      push item
      @names[use_name] = next_index
      nil
    end
    def each_with_key
      invert = @names.invert
      each_with_index do |value, idx|
        key = invert[idx]
        yield value, key
      end
      nil
    end
    def key? key
      @names.key? key
    end
    def at_key key
      if key? key
        self[@names[key]]
      else
        if @on_no_key
          @on_no_key.call(self, key)
        else
          fail "no item at key #{key}. use key?() first."
        end
      end
    end
    def on_clobber &block
      fail("no") unless block_given?
      fail("no") if @on_clobber
      @on_clobber = block
      nil
    end
  end
end
