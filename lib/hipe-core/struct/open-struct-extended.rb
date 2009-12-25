require 'ostruct'
require 'hipe-core/struct/open-struct-common-extension'
module Hipe
  class OpenStructExtended < OpenStruct
    include Hipe::OpenStructCommonExtension
    def initialize(*args)
      super(*args)
      open_struct_common_extension_init
    end
  end
end
