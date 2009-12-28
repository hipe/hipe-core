require 'hipe-core/test/helper'
module Bacon
  class Context
    #
    # @experimental
    # create an output stream used for writing notices during tests.
    #
    def notice_stream()
      Hipe::Test::Helper::NoticeStream.get(caller)
    end

    def skipit(desc)
      puts %{SKIPPING #{desc}}
    end
  end
end
