require 'sfrp/raw/elements'
require 'sfrp/raw/exception'
require 'sfrp/raw/expression'
require 'sfrp/raw/namespace'
require 'sfrp/raw/dsl'

module SFRP
  module Raw
    class Set
      def initialize(&block)
        @infixies = []
        @inits = []
        @prim_tconsts = []
        @output_node_strs = []
        @vconst_h = {}
        @func_h = {}
        @tconst_h = {}
        @node_h = {}
        block.call(self) if block
        vconst_refs.each { |vr| append_literal_vconst(vr.relative_name) }
      end

      def to_flat
        Flat::Set.new do |dest_set|
          [
            @func_h, @tconst_h, @vconst_h, @node_h
          ].flat_map(&:values).each { |e| e.gen_flat(self, dest_set) }
          @inits.each { |i| i.gen_flat(self, dest_set) }
          @output_node_strs.each { |s| dest_set.append_output_node_str(s) }
        end
      end

      def <<(element)
        case element
        when Function
          @func_h[element.absolute_name] = element
        when TConst
          @tconst_h[element.absolute_name] = element
          element.vconsts.each { |v| @vconst_h[v.absolute_name] = v }
        when PrimTConst
          @tconst_h[element.absolute_name] = element
          @prim_tconsts << element
        when Node
          @node_h[element.absolute_name] = element
        when Output
          self << element.convert
          @output_node_strs << element.absolute_name
        when Input
          self << element.convert
        when Infix
          @infixies << element
        when Init
          @inits << element
        else
          raise
        end
      end

      def weakest_op_position(ns, func_refs)
        ab_func_names = func_refs.map { |fr| func(ns, fr).absolute_name }
        infix_h = Hash[@infixies.map { |i| [i.absolute_func_name(self), i] }]
        ab_func_names.each_with_index.map do |x, idx|
          [(infix_h.key?(x) ? infix_h[x].absolute_priority(idx) : [0, 0]), idx]
        end.min[1]
      end

      def func(ns, func_ref)
        resolve(ns, func_ref, @func_h)
      end

      def vconst(ns, vconst_ref)
        resolve(ns, vconst_ref, @vconst_h)
      end

      def node(ns, node_ref)
        resolve(ns, node_ref, @node_h)
      end

      def tconst(ns, tconst_ref)
        resolve(ns, tconst_ref, @tconst_h)
      end

      private

      def resolve(ns, ref, hash)
        hits = ns.search_for_absolute_names(ref).select { |x| hash.key?(x) }
        raise NameError.new(ref.to_s) if hits.empty?
        raise AmbiguousNameError.new(ref.to_s, hits) if hits.size > 1
        hash[hits[0]]
      end

      def vconst_refs
        elements = [@func_h, @node_h].flat_map(&:values)
        elements.flat_map(&:vconst_refs)
      end

      def append_literal_vconst(str)
        return unless str =~ /^[0-9].*/
        @prim_tconsts.each do |prim_tconst|
          next unless prim_tconst.vconst_match?(str)
          new_vconst = prim_tconst.make_vconst(str)
          unless @vconst_h.key?(new_vconst.absolute_name)
            @vconst_h[new_vconst.absolute_name] = new_vconst
          end
        end
      end
    end
  end
end
