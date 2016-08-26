module SFRP
  module Mono
    class Node
      NodeRef = Struct.new(:node_str, :last)

      attr_reader :str

      def initialize(
        str, type_str, node_refs, eval_func_str, init_func_str = nil
      )
        @str = str
        @type_str = type_str
        @node_refs = node_refs
        @eval_func_str = eval_func_str
        @init_func_str = init_func_str
      end

      def comp
        [@str, @type_str, @node_refs, @eval_func_str, @init_func_str]
      end

      def ==(other)
        comp == other.comp
      end

      # Is this node initialized?
      def initialized?
        @init_func_str
      end

      # Name of variable to hold current and last evaluated value of this node.
      def low_node_str
        @str
      end

      def memory_used_to_eval_node(set)
        set.func(@eval_func_str).memory(set)
      end

      def memory_used_to_init_node(set)
        return Memory.empty unless initialized?
        set.func(@init_func_str).memory(set)
      end

      def memory_used_to_hold_node(set)
        set.type(@type_str).memory(set)
      end

      # Return referrence name of current evaluated value of this node.
      def low_node_ref_current_str
        index = (initialized? ? 'c' : '0')
        "#{low_node_str}[#{index}]"
      end

      # Return referrence name of last evaluated value of this node.
      def low_node_ref_last_str
        "#{low_node_str}[l]"
      end

      # Return a list of nodes sorted by evaluation-order including this node.
      # The list includes only nodes (recursively) depended by this node.
      # So if you want to get a list including all nodes, you must call this
      # method for an output node.
      def sorted_node_strs(set)
        cur = current_referred_node_strs(set)
        last = last_referred_node_strs(set)
        cur + (last - cur)
      end

      # Generate a statement of initialization if needed.
      def gen_initialize_stmt(set, stmts)
        return unless initialized?
        call_exp = set.func(@init_func_str).low_call_exp([])
        stmts << L.stmt("#{low_node_str}[l] = #{call_exp}")
      end

      # Generate declaration for variable to hold value of node.
      def gen_node_var_declaration(set, stmts)
        type = set.type(@type_str)
        size = (initialized? ? '2' : '1')
        stmts << L.stmt("#{type.low_type_str} #{low_node_str}[#{size}]")
      end

      # Generate ststement to evaluate this node.
      def gen_evaluate_stmt(set, stmts)
        arg_exps = @node_refs.map do |node_ref|
          n = set.node(node_ref.node_str)
          node_ref.last ? n.low_node_ref_last_str : n.low_node_ref_current_str
        end
        call_exp = set.func(@eval_func_str).low_call_exp(arg_exps)
        stmts << L.stmt("#{low_node_ref_current_str} = #{call_exp}")
      end

      # Generate statement to mark node[l].
      def gen_node_var_mark_stmt(set, stmts)
        return unless initialized?
        return unless set.type(@type_str).need_mark?(set)
        mark_func_str = set.type(@type_str).low_mark_func_str
        stmts << L.stmt("#{mark_func_str}(#{low_node_str}[l])")
      end

      protected

      # Return a list of (recursively) current-referred nodes including myself.
      def current_referred_node_strs(set, visited = {})
        return [] if visited.key?(@str)
        visited[@str] = true
        prereq_node_strs = @node_refs.reject(&:last).flat_map do |r|
          set.node(r.node_str).current_referred_node_strs(set, visited)
        end
        prereq_node_strs + [@str]
      end

      # Return a list of (recursively) last-referred nodes.
      def last_referred_node_strs(set, visited = {})
        return [] if visited.key?(@str)
        visited[@str] = true
        rec = @node_refs.reject(&:last).flat_map do |r|
          set.node(r.node_str).last_referred_node_strs(set, visited)
        end
        (@node_refs.select(&:last).map(&:node_str) + rec).uniq
      end
    end
  end
end
