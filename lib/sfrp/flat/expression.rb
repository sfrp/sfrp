module SFRP
  module Flat
    class FuncCallExp < Struct.new(:func_str, :arg_exps)
      def lift_node_ref(collected_node_refs)
        args = arg_exps.map { |e| e.lift_node_ref(collected_node_refs) }
        FuncCallExp.new(func_str, args)
      end

      def alpha_convert(table, serial)
        args = arg_exps.map { |e| e.alpha_convert(table, serial) }
        FuncCallExp.new(func_str, args)
      end

      def to_poly
        P.call_e(func_str, *arg_exps.map(&:to_poly))
      end
    end

    class VConstCallExp < Struct.new(:vconst_str, :arg_exps)
      def lift_node_ref(collected_node_refs)
        args = arg_exps.map { |e| e.lift_node_ref(collected_node_refs) }
        VConstCallExp.new(vconst_str, args)
      end

      def alpha_convert(table, serial)
        args = arg_exps.map { |e| e.alpha_convert(table, serial) }
        VConstCallExp.new(vconst_str, args)
      end

      def to_poly
        P.vc_call_e(vconst_str, *arg_exps.map(&:to_poly))
      end
    end

    class NodeRefExp < Struct.new(:node_str, :last)
      NodeRef = Struct.new(:node_str, :last)

      def lift_node_ref(collected_node_refs)
        node_ref = NodeRef.new(node_str, last)
        unless collected_node_refs.include?(node_ref)
          collected_node_refs << node_ref
        end
        VarRefExp.new("__node_ref_#{collected_node_refs.index(node_ref)}")
      end

      def alpha_convert(_table, _serial)
        self
      end

      def to_poly
        raise NodeRefInIllegalPositionError.new(node_str)
      end
    end

    class MatchExp < Struct.new(:left_exp, :cases)
      Case = Struct.new(:pattern, :exp)

      class Pattern < Struct.new(:vconst_str, :ref_var_str, :args)
        def alpha_convert(table, serial)
          new_ref_var_str =
            ref_var_str && (table[ref_var_str] = "_alpha#{serial.shift}")
          new_args = args.map { |a| a.alpha_convert(table, serial) }
          Pattern.new(vconst_str, new_ref_var_str, new_args)
        end

        def var_strs
          [ref_var_str, *args.flat_map(&:var_strs)].reject(&:nil?)
        end

        def duplicated_var_check
          vstrs = var_strs
          vstrs.each do |s|
            raise DuplicatedVariableError.new(s) if vstrs.count(s) > 1
          end
        end

        def to_poly
          Poly::Pattern.new(vconst_str, ref_var_str, args.map(&:to_poly))
        end
      end

      def lift_node_ref(collected_node_refs)
        new_left_exp = left_exp.lift_node_ref(collected_node_refs)
        new_cases = cases.map do |c|
          Case.new(c.pattern, c.exp.lift_node_ref(collected_node_refs))
        end
        MatchExp.new(new_left_exp, new_cases)
      end

      def alpha_convert(table, serial)
        new_left_exp = left_exp.alpha_convert(table, serial)
        new_cases = cases.map do |c|
          c.pattern.duplicated_var_check
          new_table = table.clone
          new_pattern = c.pattern.alpha_convert(new_table, serial)
          new_exp = c.exp.alpha_convert(new_table, serial)
          Case.new(new_pattern, new_exp)
        end
        MatchExp.new(new_left_exp, new_cases)
      end

      def to_poly
        poly_cases = cases.map do |c|
          Poly::MatchExp::Case.new(c.pattern.to_poly, c.exp.to_poly)
        end
        Poly::MatchExp.new(left_exp.to_poly, poly_cases)
      end
    end

    class VarRefExp < Struct.new(:var_str)
      def lift_node_ref(_collected_node_refs)
        self
      end

      def alpha_convert(table, _)
        raise UnboundLocalVariableError.new(var_str) unless table.key?(var_str)
        VarRefExp.new(table[var_str])
      end

      def to_poly
        P.v_e(var_str)
      end
    end
  end
end
