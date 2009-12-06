module Hipe
  module AsciiTypesetting
    def self.wordwrap text, line_width  # thanks rails
      text.split("\n").collect do |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
      end * "\n"
    end
    def self.truncate(str,max_len,ellipses='...')
      if (str.nil?) then ''
      elsif (str.length <= max_len) then str
      elsif (max_len <= ellipses.length) then str[0,max_len]
      else; str[0,max_len-ellipses.length]+ellipses end
    end
    
    module FormattableString
      def self.new(s)
        s.extend self
        s
      end
      def word_wrap_once!(length)
        re = /^(.{0,#{length}})(?:\s+|$)(.*)/
        md = re.match(self)
        if (md)
          first_line, remainder = md.captures
          self.replace(remainder)
          first_line
        else
          ''
        end
      end
      
      def word_wrap!(length)
        self.replace(Hipe::AsciiTypesetting::wordwrap(self,length))
        self
      end
      
      # num will be mixed string or Fixnum one day
      def indent!(num)
        replace( ' ' * num + self.gsub("\n", "\n"+' '*num))
        self
      end
      
      # try to truncate without breaking any sentences.  I.e, return 
      # as many contiguous sentences as you can that start from the beginning
      # and have a total length less than or equal to length.
      # If the first sentence is longer than length, then truncate with '...' ellipses
      # A sentence is defined as a string ending in '?','.', or '!' followed 
      # by ' ' or end of string
      def sentence_wrap_once!(length)
        md = /^(.{0,#{length-1}}[^\?\.!])(?:([\?\.!]+) +|$)(.*)$/.match(self)
        if md
          first,punct,remainder = md.captures
          first << punct if punct
          replace(remainder)
        else
          first = word_wrap_once!(length-3) + '...'
        end
        first
      end
    end         
  end
end
