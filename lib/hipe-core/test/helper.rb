module Hipe
  module Test
    class Helper
      # For tests that want help clearing the contents of and writing to a temp folder, etc
      # for example:
      #    MyHelper = Hipe::Test::Helper.singleton(Your::Module)
      #    MyHelper.clear_writable_temporary_directory!
      #    some_path_to_write_to = File.join MyHelper.writable_temporary_directory, 'some-folder'
      #
      def self.shell!(string)  # @TODO huge security hole? just for writing tests
        rs = %x{hipe-cli-argv-echo #{string}}  # popen3 won't work b/c it escapes the string into one argument
        Marshal.load(rs)
      end
      @singletons = {}
      attr_reader :writable_temporary_directory
      def self.singleton(project_module)
        raise TypeError(%{needed module had #{project_module.inspect}}) unless Module === project_module
        @singletons[project_module] ||= self.new(project_module)
      end
      class << self
        alias_method :[], :singleton
      end
      def initialize(project_module)
        @project_module = project_module
        @writable_temporary_directory = File.join(project_module.const_get('DIR'), 'spec','writable-tmp')
      end
      def clear_writable_temporary_directory!
        dirpath = @writable_temporary_directory
        raise %{something looks wrong with writable_temporary_directory name: "#{dirpath}"} unless dirpath =~ /writable-tmp$/
        raise %{"#{dirpath}" must exist} unless File.exist?(dirpath)
        raise %{"#{dirpath}" must be writable} unless File.writable?(dirpath)
        Dir[File.join(dirpath,'/*')].each do |filename|
          if (File.directory? filename)
            FileUtils.rm_rf(filename)
          else
            File.unlink(filename)
          end
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
