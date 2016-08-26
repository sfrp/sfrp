require 'sfrp/mono/environment'
require 'sfrp/mono/expression'
require 'sfrp/mono/function'
require 'sfrp/mono/memory'
require 'sfrp/mono/node'
require 'sfrp/mono/pattern'
require 'sfrp/mono/type'
require 'sfrp/mono/vconst'
require 'sfrp/mono/dsl'

module SFRP
  module Mono
    class Set
      def initialize(&block)
        @func_h = {}
        @node_h = {}
        @type_h = {}
        @vconst_h = {}
        @output_node_strs = []
        @init_func_strs = []
        @type_alias_h = {}
        @constructor_alias_h = {}
        block.call(self) if block
      end

      def to_low(include_file_strs = [])
        Low::Set.new do |low_set|
          include_file_strs.each { |s| low_set << L.include_dq(s) }
          @type_alias_h.each do |alias_str, original_str|
            low_set << type(original_str).low_typedef_for_alias(alias_str)
          end
          @constructor_alias_h.each do |alias_str, original_str|
            low_set << vconst(original_str).low_macro_for_alias(alias_str)
          end
          @func_h.values.each { |func| func.gen(self, low_set) }
          @type_h.values.each { |type| type.gen(self, low_set) }
          gen_main_func(low_set)
        end
      end

      def check
        # TODO: Check that all init_func does not waste any memory.
        # TODO: Check completeness of pattern matchings.
      end

      def memory(type_str)
        @memory ||= begin
          to_init_nodes = nodes.reduce(Memory.empty) do |m, node|
            m.and(node.memory_used_to_init_node(self))
          end
          to_hold_memoized_nodes = nodes.reduce(Memory.empty) do |m, node|
            node.initialized? ? m.and(node.memory_used_to_hold_node(self)) : m
          end
          to_eval_nodes = nodes.reduce(Memory.empty) do |m, node|
            m.and(node.memory_used_to_eval_node(self))
          end
          to_hold_memoized_nodes.and(to_eval_nodes).or(to_init_nodes)
        end
        @memory.count(type_str)
      end

      def <<(element)
        case element
        when Function
          @func_h[element.str] = element
        when Node
          @node_h[element.str] = element
        when Type
          @type_h[element.str] = element
        when VConst
          @vconst_h[element.str] = element
        else
          raise
        end
      end

      def append_output_node_str(output_node_str)
        @output_node_strs << output_node_str
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

      def type(type_str)
        raise type_str unless @type_h.key?(type_str)
        @type_h[type_str]
      end

      def vconst(vconst_str)
        raise vconst_str unless @vconst_h.key?(vconst_str)
        @vconst_h[vconst_str]
      end

      def funcs
        @func_h.values
      end

      def nodes
        @node_h.values
      end

      def types
        @type_h.values
      end

      def vconsts
        @vconst_h.values
      end

      private

      # All used nodes.
      def used_nodes
        node_strs = @output_node_strs.flat_map do |node_str|
          node(node_str).sorted_node_strs(self)
        end
        node_strs.uniq.map { |node_str| node(node_str) }
      end

      # Generate the main-function.
      def gen_main_func(dest_set)
        dest_set << L.function('main', 'int') do |f|
          f << L.stmt('int c = 0, l = 1')
          used_nodes.each { |node| node.gen_node_var_declaration(self, f) }
          @init_func_strs.each do |func_str|
            f << L.stmt(func(func_str).low_call_exp([]))
          end
          used_nodes.each { |node| node.gen_initialize_stmt(self, f) }
          f << L.while('1') do |wh|
            @type_h.values.each { |type| type.gen_mark_cleanup_stmt(self, wh) }
            used_nodes.each { |node| node.gen_node_var_mark_stmt(self, wh) }
            used_nodes.each { |node| node.gen_evaluate_stmt(self, wh) }
            wh << L.stmt('c ^= 1, l ^= 1')
          end
          f << L.stmt('return 0')
        end
      end
    end
  end
end
