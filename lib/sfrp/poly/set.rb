require 'sfrp/poly/exception'
require 'sfrp/poly/typing'
require 'sfrp/poly/elements'
require 'sfrp/poly/expression'
require 'sfrp/poly/monofier'
require 'sfrp/poly/dsl'

module SFRP
  module Poly
    class Set
      def initialize(&block)
        @func_h = {}
        @node_h = {}
        @tconst_h = {}
        @vconst_h = {}
        @output_node_strs = []
        @init_func_strs = []
        block.call(self) if block
      end

      def to_mono
        Mono::Set.new do |dest_set|
          @func_h.values.each { |f| f.ftyping(self) }
          @node_h.values.each do |n|
            n.check_recursion(self)
            n.typing(self)
          end
          Monofier.new(self, dest_set) do |m|
            @init_func_strs.each do |func_str|
              mono_func_str = m.use_func(func_str, func(func_str).ftyping(self))
              dest_set.append_init_func_str(mono_func_str)
            end
            @node_h.values.each do |node|
              dest_set << node.to_mono(m)
            end
            @output_node_strs.each do |node_str|
              dest_set.append_output_node_str(m.use_node(node_str))
            end
          end
        end
      end

      def <<(element)
        case element
        when Function
          @func_h[element.str] = element
        when Node
          @node_h[element.str] = element
        when TConst
          @tconst_h[element.str] = element
        when VConst
          @vconst_h[element.str] = element
        else
          raise
        end
      end

      def append_output_node_str(node_str)
        @output_node_strs << node_str
      end

      def append_init_func_str(init_func_str)
        @init_func_strs << init_func_str
      end

      def func(func_str)
        raise func_str unless @func_h.key?(func_str)
        @func_h[func_str]
      end

      def node(node_str)
        raise node_str unless @node_h.key?(node_str)
        @node_h[node_str]
      end

      def tconst(tconst_str)
        raise tconst_str unless @tconst_h.key?(tconst_str )
        @tconst_h[tconst_str ]
      end

      def vconst(vconst_str)
        raise vconst_str unless @vconst_h.key?(vconst_str)
        @vconst_h[vconst_str]
      end
    end
  end
end
