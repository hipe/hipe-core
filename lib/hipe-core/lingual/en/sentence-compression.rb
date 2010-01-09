# bacon spec/lingual/en/spec_sentence-compression.rb
require 'hipe-core/lingual/en'
require 'diff/lcs'
require 'ruby-debug'

module Hipe::Lingual::En
  module SentenceCompressionInternal
    module Symbol
    end

    class Terminal < String
      include Symbol
      alias_method :say, :to_s
    end

    class NonTerminal < Array
      include Symbol
      def say; map{|x| x.say}*' '; end
      alias_method :to_s, :say
      def prune
        (size == 1) ? self[0] : self
      end
    end

    class Span < NonTerminal
    end

    class List < NonTerminal
      attr_reader :conjunction
      def initialize
        @conjunction = :and
      end
      def say
        Hipe::Lingual::En::List[ map{|x| x.say } ].send(@conjunction)
      end
      def push(item)
        if (item.kind_of?(List) && item.conjunction == @conjunction)
          concat(item)
        else
          super
        end
      end
    end

    class Sentence < Span
      include Enumerable
      def initialize string=nil
        super()
        if string
          raise ArgumentError.new("Not stringable: #{string.inspect}") unless string.respond_to?(:to_str)
          string.split(' ').each do |token|
            push(Terminal.new(token))
          end
        end
      end
    end
  end

  class SentenceCompression < Array
    include SentenceCompressionInternal
    List = SentenceCompressionInternal::List # conflicts with En::List
    def say
      map{|x| x.say} * '  '
    end
    alias_method :to_s, :say
    def initialize
      super()
      @threshold = 0.23
    end
    def <<(string)
      new_sentence = Sentence.new(string)
      if (size==0)
        push new_sentence
      else
        lcs = Diff::LCS.LCS(last, new_sentence)
        percent_same = lcs.size.to_f /  last.size.to_f
        if (percent_same < @threshold)
          push new_sentence
          return self
        end
        debugger if $ddd
        diffA = Diff::LCS.diff(lcs, last)
        diffB = Diff::LCS.diff(lcs, new_sentence)
        squezes = Array.new(lcs.size + 1)
        [diffA, diffB].each do |diff|
          offset_offset = 0
          diff.each do |chunk|
            offset = chunk[0].position + offset_offset
            squezes[offset] ||= List.new
            new_span = Span.new
            chunk.each do |insertion|
              raise "fundamentally flawed" if '+' != insertion.action
              new_span.push insertion.element
            end
            squezes[offset].push new_span.prune
            offset_offset -= chunk.size
          end
        end
        composite_sentence = Sentence.new
        lcs.each_with_index do |token, idx|
          composite_sentence.push squezes[idx].prune if squezes[idx]
          composite_sentence.push token
        end
        composite_sentence.push squezes.last if squezes.last
        self[size-1] = composite_sentence
      end
      self
    end
  end
end
