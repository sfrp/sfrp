module SFRP
  module Mono
    class Pattern
      def initialize(type_str, vconst_str, ref_var_str, arg_patterns)
        @type_str = type_str
        @vconst_str = vconst_str
        @ref_var_str = ref_var_str
        @arg_patterns = arg_patterns
      end

      def comp
        [@type_str, @vconst_str, @ref_var_str, @arg_patterns]
      end

      def ==(other)
        comp == other.comp
      end

      def any?
        @vconst_str.nil?
      end

      def named?
        @ref_var_str
      end

      # Return whole conditional-low-exps for the pattern-matching.
      def low_cond_exps(set, receiver_exp)
        return [] if any?
        vconst = set.vconst(@vconst_str)
        children = @arg_patterns.each_with_index.flat_map do |pat, mem_id|
          new_receiver = child_receiver_exp(set, receiver_exp, mem_id)
          pat.low_cond_exps(set, new_receiver)
        end
        vconst.low_compare_exps(set, receiver_exp) + children
      end

      # Return whole let-low-exps for the pattern-matching.
      def low_let_exps(set, receiver_exp, env)
        env.add_var(@ref_var_str, @type_str) if named?
        lets = (named? ? ["#{@ref_var_str} = (#{receiver_exp})"] : [])
        return lets if any?
        children = @arg_patterns.each_with_index.flat_map do |pat, mem_id|
          new_receiver = child_receiver_exp(set, receiver_exp, mem_id)
          pat.low_let_exps(set, new_receiver, env)
        end
        lets + children
      end

      private

      def child_receiver_exp(set, parent_receiver_exp, member_id)
        type = set.type(@type_str)
        terms_str = type.terms_access_str(parent_receiver_exp)
        "#{terms_str}.term#{type.term_id(@vconst_str)}.member#{member_id}"
      end
    end
  end
end
