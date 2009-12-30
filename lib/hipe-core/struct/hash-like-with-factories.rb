# bacon spec/struct/spec_hash-like-with-factories.rb
# bacon spec/struct/spec_table.rb

module Hipe
  class HashLikeWithFactories
    # keeps a collection of objects by name (hash-like), also keeps a hash of factories to
    # use when the object at that key isn't present.
    # Oh crap, i proabably could have done this in three lines.
    # no just kidding.  this might be useful sometimes
    #
    # This is a way to lazily create objects only when they are needed (For example the different
    # table renderers.  When we construct a table we want to "register" all of the renderers
    # but we don't want to create objects of each one.)
    #
    # @todo - factory is a misnomer but we like it.  Keep it?

    #
    # This is experimental and in flux. Don't use this class without adding your class name to the below list:
    #   - Hipe::Table
    #

    # makes an object with a very restricted interface used only to access the elements of this HashLike
    class LimitedAccessor
      def initialize(it)
        @it = it
      end
      def [](name)
        @it[name]
      end
    end

    def self.register_factory(name, klass)
      @factories ||= {}
      @factories[name] = klass
    end

    def self.factories
      @factories
    end

    def initialize
      @table = {}
    end

    def accessor
      LimitedAccessor.new(self)
    end

    def size
      keys.size
    end

    def keys
      @table.keys | self.class.factories.keys
    end

    def each
      keys.each do |key|
        yield self[key]
      end
    end

    # allows querying the renderers list by name w/o constructing objects from the factories
    def has_key? key
      keys.include? key
    end

    def has_instance? key
      @table.has_key? key
    end

    def []= key, value
      if (@table[key])
        raise ArgumentError.new("This is non-clobbering.  Call delete() first for #{key.inspect}")
      end
      @table[key] = value
    end

    def [] key
      @table[key] || (self.class.factories[key] && (@table[key] = self.class.factories[key].new)) || nil
    end

    def delete(key)
      @table.delete(key)
    end
  end
end
