require 'hipe-core'

module Hipe
  class ClassLoader
    # warning! whether this will remain a class method is experimental
    # Assume that a class NamedLikeThis is in a file named-like-this.rb,
    # and require the file and return the class.  The class must exist in some module.
    # which gets passed in as the second parameter.
    # @param filename [String] a path to the file suitable to be used with "require()"
    # @param container_module [Module] the module the class is expected to be defined in.
    # @return [Class] the class found in the file.
    def self.from_file! filename, container_module
      mod = container_module
      require filename
      raise Hipe::Exception.new(%{filenames with classes must be lowcase and dashes, not "#{filename}"},
        :type => :bad_plugin_filename) unless md = %r{/([-a-z]+)\.rb$}.match(filename)
      class_name_singular = md[1].gsub(/(^|-)([a-z])/){$2.upcase}
      class_names = [class_name_singular, %{#{class_name_singular}s}]
      class_name = class_names.detect { |class_name| mod.constants.include?(class_name) }
      return mod.const_get(class_name) if class_name
      raise Hipe::Exception.new(%{couldn't find class #{class_name_singular} or #{class_name_singular} in #{mod} in #{filename}},
        :type=>:plugin_not_found)
    end
  end
end
