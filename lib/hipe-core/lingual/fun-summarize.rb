require 'hipe-core/struct/diff'
module Hipe
  module FunSummarize
    # expects an arbirarily deep nested hash with symbol names and values that are either
    # (leave node) an integer or (tree node) another such hash.  returns an array of lines indented appropirately
    def self._fun_summarize(hash, indent_amt='  ', current_indent='', parent_key = nil)
      my_total = 0;
      my_lines = []
      hash.each do |key,value|
        left_side = ([parent_key.to_s,key.to_s].compact * '_').gsub!(/_/, ' ')
        if (value.instance_of? Fixnum)
          my_lines << %{#{current_indent}#{left_side}: #{value}}
          my_total += value
        else
          child_lines,child_total = _fun_summarize(value, indent_amt, current_indent+indent_amt, key)
          my_lines << %{#{current_indent}#{left_side} (#{child_total} total):}
          my_total += child_total
          my_lines += child_lines
        end
      end
      [my_lines, my_total]
    end

    def self.summarize_totals(hash, indent_amt='  ')
      lines, total = _fun_summarize(hash, indent_amt, current_indent='  ')
      %{(#{total} total):\n}+(lines * "\n")
    end

    # oops we should have made this an object not a class @todo
    def self.clear
      @last_template = nil
      @last_values = nil
    end

    # say as little of a sentence as you need to.
    def self.minimize template, values
      @last_template ||= nil
      @last_values ||= nil
      if (template == @last_template)
        # they will always have the same keys, so we look at middle
        diff = StructDiff::diff(@last_values, values)
        @last_values = values
        if (diff.diff?)
          ret = " and "+(diff.middle_diff.map do |key,value|
            value_string = value.right.to_s.match(/^[0-9]+$/) ? value.right.to_s : %{"#{value.right}"}
            %{#{key}#{value_string}}
          end * " with ")
        else
          ret = "\n" + template_render( template, values )
        end
      else
        @last_template = template
        @last_values = values
        ret = "\n" + template_render( template, values )
      end
      ret
    end

    def self.template_render template, values
      ret = template.clone #* ''TODO'' test if this is necessary
      values.each{|k,v| ret.gsub! %{%%#{k}%%}, v}
      ret
    end
  end
end
