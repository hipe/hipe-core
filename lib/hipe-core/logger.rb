module Hipe
  module Cli
    module Loggable
      module Constants
        INFO = 2
        DETAIL = 4
        INSPECT = 6
        MICROSCOPE = 7
      end
      # print the string that results from calling the block iff log_level_int is less than or equal to
      # the log level set by passing one or more --debug (-d) flags

      # Log levels: level 0 means output no matter what. Level 1 is output informational stuff
      # perhaps for the client (not developer) to see.  Level 2 and above are informational and for the developer
      # or user trying to troubleshoot a bug.  there is no upper bounds to the debug levels.  but we might restrict 
      # it to the range (0..10] (sic) and use floats instead; one day.
      
      # if there is no @cli_log_level set at the time this is called, it probably means that the command-
      # line processor hasn't been called yet, in which case we output the message no matter what.
      
      # if a string starts with the null character (zero, ie "\000") it means "do not indent this line"      
      # (otherwise, lines will be indented according to their loglevel)
      # if you end a string with the null character (zero, ie \000) it means "no newline afterwards"
      def log(log_level_int, &print_block)
        if @cli_always_log || ( !@cli_log_level.nil? && log_level_int <= @cli_log_level )
          str ||= yield;
          unless(str.instance_of? String)
            $stderr.print "misuse of cli_log() -- block should return string at "+caller[0]+"\n"
            false
          else 
            $stderr.print('  '*[log_level_int-2,0].max) unless str[0] == 0
            str = str[1..-1] if (0==str[0])
            $stderr.print str
            $stderr.print("\n") unless str[-1] == 0       
            true
          end
        else
          false
        end
      end
    end # Loggable
    
    class Logger
      @@singleton = nil            
      include Loggable
      def self.singleton
        if @@singleton.nil?
          @@singleton = Logger.new
        end
        @@singleton
      end      
    end
  end # Cli
end # Hipe