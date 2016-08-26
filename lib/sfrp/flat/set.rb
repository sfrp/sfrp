require 'sfrp/flat/elements'
require 'sfrp/flat/exception'
require 'sfrp/flat/expression'
require 'sfrp/flat/dsl'

module SFRP
  module Flat
    class Set
      def initialize(&block)
        @funcs = []
        @tconsts = []
        @vconsts = []
        @nodes = []
        @output_node_strs = []
        @init_func_strs = []
        block.call(self) if block
      end

      def to_poly
        Poly::Set.new do |dest_set|
          (@funcs + @tconsts + @vconsts + @nodes).each do |element|
            element.to_poly(self, dest_set)
          end
          @output_node_strs.each { |s| dest_set.append_output_node_str(s) }
          @init_func_strs.each { |s| dest_set.append_init_func_str(s) }
        end
      end

      def append_output_node_str(node_str)
        @output_node_strs << node_str
      end

      def append_init_func_str(init_func_str)
        @init_func_strs << init_func_str
      end

      def <<(element)
        case element
        when Function
          @funcs << element
        when TConst
          @tconsts << element
        when VConst
          @vconsts << element
        when Node
          @nodes << element
        else
          raise
        end
      end

      def tconst(str)
        @tconsts.find { |tconst| tconst.str == str }
      end
    end
  end
end
