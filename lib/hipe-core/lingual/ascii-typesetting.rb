module Hipe
  module AsciiTypesetting

    # it would be nice if
    # these methods could be 1) extended by a module that wants them as module methods,
    # 2) they can be extended by a class that wants them as class methods,
    # 3) they can be included by a class that wants them as instance methods, or 4) they can be called
    # as module methods of the module containing this comment.
    #
    module Methods
      def wordwrap text, line_width  # thanks rails
        throw TypeError.new(%{needed String had #{text.inspect}}) unless text.kind_of? String
        text.split("\n").collect do |line|
          line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
      end
      def truncate(str,max_len,ellipses='...')
        if (str.nil?) then ''
        elsif (str.length <= max_len) then str
        elsif (max_len <= ellipses.length) then str[0,max_len]
        else; str[0,max_len-ellipses.length]+ellipses end
      end

      def recursive_brackets list, left, right
        return '' if list.size == 0  # not the official base case.  just being cautius
        ret = list[0]
        if list.size > 1
          ret += left + recursive_brackets(list.slice(1,list.size-1), left, right) + right
        end
        ret
      end
    end

    extend Methods

    module FormattableString
      def self.[](str)
        other = (String === str) ? str.dup : str.to_s
        # this caused some bugs when we didn't dup it, when running the same code twice
        # we dup it only if it is a string, no need to incur the overhead. but str.to_s returns self
        other.extend self
        other
      end
      def word_wrap_once!(length)
        re = /^(.{0,#{length}})(?:\s+|$)(.*)/
        md = re.match(self)
        if (md)  # shouldn't ever fail the above regex as long as we are string, no? but just to be sae
          first_line, remainder = md.captures
          self.replace(remainder)
          first_line
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
