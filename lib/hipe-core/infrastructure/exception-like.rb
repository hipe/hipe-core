module Hipe
  module CommonExceptionClassMethods
    attr_accessor :exception_modules
    attr_accessor :default_exception_class
    def modules=(mods)
      @exception_modules = mods
    end
    def factory(*args)
      details = args.detect{|x| x.respond_to? :[]}
      @exception_modules ||= []
      use_this_class = nil
      if (details && details[:type])
        class_name = details[:type].to_s.gsub(/(?:^|_)([a-z])/){$1.upcase}
        @exception_modules.each do |mod|
          if mod.constants.include? class_name
            use_this_class = mod.const_get class_name
            break
          end
        end
      end
      use_this_class ||=  ( @default_exception_class || self )
      arity = use_this_class.method('new').arity
      if arity > 0 && arity < args.size
        sliced = args.slice!(arity.abs,args.size-arity)
        details[:sliced] = sliced if details
      end
      return use_this_class.new(*args)
    end
    alias_method :[], :factory
  end

  module ExceptionLike
    def self.included klass
      klass.extend CommonExceptionClassMethods
      klass.instance_variable_set('@exception_modules',[]) unless
        klass.instance_variable_get('@exception_modules')
    end
  end
end
