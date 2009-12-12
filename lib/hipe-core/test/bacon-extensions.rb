module Bacon
 class Context
   def skipit(description, &block)
     puts %{- SKIPPING #{description}}
   end
  end
end
