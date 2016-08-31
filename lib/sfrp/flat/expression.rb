module SFRP
  module Flat
    class FuncCallExp < Struct.new(:func_str, :arg_exps, :sp)
      def lift_node_ref(collected_node_refs)
        args = arg_exps.map { |e| e.lift_node_ref(collected_node_refs) }
        FuncCallExp.new(func_str, args, sp)
      end

      def to_poly
        P.call_e(func_str, *arg_exps.map(&:to_poly))
      end
    end

    class VConstCallExp < Struct.new(:vconst_str, :arg_exps, :sp)
      def lift_node_ref(collected_node_refs)
        args = arg_exps.map { |e| e.lift_node_ref(collected_node_refs) }
        VConstCallExp.new(vconst_str, args, sp)
      end

      def to_poly
        P.vc_call_e(vconst_str, *arg_exps.map(&:to_poly))
      end
    end

    class NodeRefExp < Struct.new(:node_str, :last, :sp)
      NodeRef = Struct.new(:node_str, :last)

      def lift_node_ref(collected_node_refs)
        node_ref = NodeRef.new(node_str, last)
        unless collected_node_refs.include?(node_ref)
          collected_node_refs << node_ref
        end
        VarRefExp.new("__node_ref_#{collected_node_refs.index(node_ref)}", sp)
      end

      def to_poly
        raise NodeRefInIllegalPositionError.new(node_str, sp)
      end
    end

    class MatchExp < Struct.new(:left_exp, :cases, :sp)
      Case = Struct.new(:pattern, :exp)

      class Pattern < Struct.new(:vconst_str, :ref_var_str, :args, :sp)
        def to_poly
          Poly::Pattern.new(vconst_str, ref_var_str, args.map(&:to_poly))
        end
      end

      def lift_node_ref(collected_node_refs)
        new_left_exp = left_exp.lift_node_ref(collected_node_refs)
        new_cases = cases.map do |c|
          Case.new(c.pattern, c.exp.lift_node_ref(collected_node_refs))
        end
        MatchExp.new(new_left_exp, new_cases, sp)
      end

      def to_poly
        poly_cases = cases.map do |c|
          Poly::MatchExp::Case.new(c.pattern.to_poly, c.exp.to_poly)
        end
        Poly::MatchExp.new(left_exp.to_poly, poly_cases)
      end
    end

    class VarRefExp < Struct.new(:var_str, :sp)
      def lift_node_ref(_collected_node_refs)
        self
      end

      def to_poly
        P.v_e(var_str)
      end
    end
  end
end
