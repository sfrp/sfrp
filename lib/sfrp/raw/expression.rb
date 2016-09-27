module SFRP
  module Raw
    class FuncCallExp < Struct.new(:func_ref, :arg_exps, :effect, :sp)
      def vconst_refs
        arg_exps.flat_map(&:vconst_refs)
      end

      def blame_side_effect
        raise IllegalSideEffectError.new(func_ref.to_s, sp) if effect
        arg_exps.each(&:blame_side_effect)
      end

      def to_flat(set, ns)
        ab_func_name = set.func(ns, func_ref, sp).absolute_name
        args = arg_exps.map { |e| e.to_flat(set, ns) }
        Flat::FuncCallExp.new(ab_func_name, args, sp)
      end
    end

    class VConstCallExp < Struct.new(:vconst_ref, :arg_exps, :sp)
      def vconst_refs
        [vconst_ref, *arg_exps.flat_map(&:vconst_refs)]
      end

      def blame_side_effect
        arg_exps.each(&:blame_side_effect)
      end

      def to_flat(set, ns)
        ab_vc_name = set.vconst(ns, vconst_ref, sp).absolute_name
        args = arg_exps.map { |e| e.to_flat(set, ns) }
        Flat::VConstCallExp.new(ab_vc_name, args, sp)
      end
    end

    class NodeRefExp < Struct.new(:node_ref, :last, :sp)
      def vconst_refs
        []
      end

      def blame_side_effect
        nil
      end

      def to_flat(set, ns)
        ab_node_name = set.node(ns, node_ref, sp).absolute_name
        Flat::NodeRefExp.new(ab_node_name, last)
      end
    end

    class MatchExp < Struct.new(:left_exp, :cases, :sp)
      Case = Struct.new(:pattern, :exp)

      class Pattern < Struct.new(:vconst_ref, :ref_var_str, :args, :sp)
        def vconst_refs
          (vconst_ref ? [vconst_ref] : []) + args.flat_map(&:vconst_refs)
        end

        def to_flat(set, ns)
          flat_args = args.map { |a| a.to_flat(set, ns) }
          if vconst_ref
            ab_vc_name = set.vconst(ns, vconst_ref, sp).absolute_name
            Flat::MatchExp::Pattern.new(ab_vc_name, ref_var_str, flat_args, sp)
          else
            Flat::MatchExp::Pattern.new(nil, ref_var_str, flat_args, sp)
          end
        end
      end

      def vconst_refs
        [left_exp, *cases.map(&:pattern), *cases.map(&:exp)].flat_map(&:vconst_refs)
      end

      def blame_side_effect
        left_exp.blame_side_effect
        cases.map(&:exp).each(&:blame_side_effect)
      end

      def to_flat(set, ns)
        flat_cases = cases.map do |c|
          flat_pattern = c.pattern.to_flat(set, ns)
          Flat::MatchExp::Case.new(flat_pattern, c.exp.to_flat(set, ns))
        end
        Flat::MatchExp.new(left_exp.to_flat(set, ns), flat_cases, sp)
      end
    end

    class VarRefExp < Struct.new(:var_str, :sp)
      def vconst_refs
        []
      end

      def blame_side_effect
        nil
      end

      def to_flat(_set, _ns)
        Flat::VarRefExp.new(var_str, sp)
      end
    end

    class SequenceExp < Struct.new(:exps, :func_refs, :sp)
      def vconst_refs
        exps.flat_map(&:vconst_refs)
      end

      def blame_side_effect
        exps.each { |e| e.blame_side_effect }
      end

      def convert(set, ns)
        return exps[0] if exps.size == 1
        pos = set.weakest_op_position(ns, func_refs, sp)
        lseq = SequenceExp.new(exps.take(pos + 1), func_refs.take(pos), sp)
        rseq = SequenceExp.new(exps.drop(pos + 1), func_refs.drop(pos + 1), sp)
        args = [lseq.convert(set, ns), rseq.convert(set, ns)]
        FuncCallExp.new(func_refs[pos], args, false, sp)
      end

      def to_flat(set, ns)
        convert(set, ns).to_flat(set, ns)
      end
    end

    module SugarExp
      def vconst_refs
        convert.vconst_refs
      end

      def blame_side_effect
        convert.blame_side_effect
      end

      def to_flat(set, ns)
        convert.to_flat(set, ns)
      end
    end

    class IfExp < Struct.new(:cond_exp, :then_exp, :else_exp, :sp)
      include SugarExp

      def convert
        cases = [
          MatchExp::Case.new(
            MatchExp::Pattern.new(Ref.new('True'), nil, [], sp), then_exp
          ),
          MatchExp::Case.new(
            MatchExp::Pattern.new(Ref.new('False'), nil, [], sp), else_exp
          )
        ]
        MatchExp.new(cond_exp, cases, sp)
      end
    end

    class LetExp < Struct.new(:exp, :assignments, :sp)
      include SugarExp

      Assignment = Struct.new(:pattern, :exp)

      def convert
        raise if assignments.empty?
        assignments.reverse.reduce(exp) do |e, ass|
          MatchExp.new(ass.exp, [MatchExp::Case.new(ass.pattern, e)], sp)
        end
      end
    end
  end
end
