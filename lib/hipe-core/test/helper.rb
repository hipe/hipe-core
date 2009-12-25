module Hipe
  module Test
    class Helper
      def self.shell!(string)  # @TODO huge security hole? just for writing tests
        rs = %x{hipe-cli-argv-echo #{string}}  # popen3 won't work b/c it escapes the string into one argument
        Marshal.load(rs)
      end
      @singletons = {}
      attr_reader :writable_tmp_dir
      def self.singleton(project_module)
        raise TypeError(%{needed module had #{project_module.inspect}}) unless Module === project_module
        @singletons[project_module] ||= self.new(project_module)
      end
      class << self
        alias_method :[], :singleton
      end
      def initialize(project_module)
        @project_module = project_module
        @writable_tmp_dir = File.join(project_module.const_get('DIR'), 'spec','writable-tmp')
      end
      def clear_writable_tmp_dir!
        dirpath = @writable_tmp_dir
        raise %{something looks wrong with writable_tmp_dir name: "#{dirpath}"} unless dirpath =~ /writable-tmp$/
        raise %{"#{dirpath}" must exist} unless File.exist?(dirpath)
        raise %{"#{dirpath}" must be writable} unless File.writable?(dirpath)
        Dir[File.join(dirpath,'/*')].each do |filename|
          File.unlink(filename)
        end
      end
      class NoticeStream < IO
        def self.get(stack)
          self.new($stdout.to_i,stack)
        end
        def initialize(fd,stack)
          super(fd)
          @caller_line = stack.shift
        end
        def write(data)
          caller_line = caller[3]
          super(%{\n>> #{data} (#{File.basename(caller_line)})})
          flush # if we don't call this it gets flushed at the end of the tests
        end
      end
    end
  end
end
