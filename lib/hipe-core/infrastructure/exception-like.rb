module Hipe
  module CommonExceptionClassMethods
    attr_accessor :exception_modules
    attr_accessor :default_exception_class
    def modules=(mods)
      @exception_modules = mods
    end
    def factory (string,details={})
      @exception_modules ||= []
      use_this_class = nil
      if (details[:type])
        if @exception_modules.size == 0
          string << %{(no exception_modules registered.)}
        else
          class_name = details[:type].to_s.gsub(/(?:^|_)([a-z])/){$1.upcase}
          @exception_modules.each do |mod|
            if mod.constants.include? class_name
              use_this_class = mod.const_get class_name
              break
            end
          end
        end
      end
      if (use_this_class.nil?)
        if (@default_exception_class)
          use_this_class = @default_exception_class
        else
          string << %{(#{details.inspect})} if (!details.respond_to?(:size) || details.size > 0)
          use_this_class = self
        end
      end
      arity = use_this_class.method('new').arity
      args = [string,details]
      if ((0..1) === arity)
        string << %{(exception class airity: #{arity})}
        args.slice!(arity,args.size-arity)
      end
      return use_this_class.new(*args)
    end
  end

  module ExceptionLike
    def self.included klass
      klass.extend CommonExceptionClassMethods
      klass.instance_variable_set('@exception_modules',[]) unless
        klass.instance_variable_get('@exception_modules')
    end
  end
end
