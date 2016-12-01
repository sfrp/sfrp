module SFRP
  module Raw
    class Function < Struct.new(:rname, :ns, :ret_ta, :pstrs, :ptas, :exp, :ffi_str, :effect)
      def absolute_name
        ns.absolute_name(rname)
      end

      def vconst_refs
        exp ? exp.vconst_refs : []
      end

      def gen_flat(src_set, dest_set)
        exp.blame_side_effect if exp && !effect
        flat_exp = exp && exp.to_flat(src_set, ns)
        flat_ret_ta = ret_ta && ret_ta.to_flat(src_set, ns)
        flat_ptas = ptas.map { |ta| ta && ta.to_flat(src_set, ns) }
        dest_set << Flat::Function.new(
          absolute_name, flat_ret_ta, pstrs, flat_ptas, flat_exp, ffi_str
        )
      end
    end

    class TConst < Struct.new(:rname, :ns, :pstrs, :vconsts, :native_str, :static)
      def absolute_name
        ns.absolute_name(rname)
      end

      def gen_flat(_src_set, dest_set)
        vconst_strs = vconsts.map(&:absolute_name)
        dest_set << Flat::TConst.new(absolute_name, pstrs, vconst_strs, native_str, static)
      end
    end

    class VConst < Struct.new(:rname, :tconst_rname, :ns, :native_str, :param_tas)
      def absolute_name
        ns.absolute_name(rname)
      end

      def gen_flat(src_set, dest_set)
        tconst_str = src_set.tconst(ns, Ref.new(tconst_rname)).absolute_name
        flat_param_tas = param_tas.map { |ta| ta.to_flat(src_set, ns) }
        dest_set << Flat::VConst.new(absolute_name, tconst_str, native_str, flat_param_tas)
      end
    end

    class PrimTConst < Struct.new(:rname, :ns, :native_str, :pat, :rep)
      def absolute_name
        ns.absolute_name(rname)
      end

      def vconst_match?(vconst_str)
        pat.match(vconst_str)
      end

      def make_vconst(vconst_str)
        raise vconst_str unless vconst_match?(vconst_str)
        VConst.new(vconst_str, rname, ns, vconst_str.gsub(pat, rep), [])
      end

      def gen_flat(_src_set, dest_set)
        dest_set << Flat::TConst.new(absolute_name, [], nil, native_str, true)
      end
    end

    class Init < Struct.new(:ns, :func_ref, :arg_exps, :line_number)
      def func_rname
        "%init#{line_number}"
      end

      def function
        exp = FuncCallExp.new(func_ref, arg_exps, true)
        Function.new(func_rname, ns, nil, [], [], exp, nil, true)
      end

      def gen_flat(src_set, dest_set)
        function.gen_flat(src_set, dest_set)
        dest_set.append_init_func_str(function.absolute_name)
      end
    end

    class Node < Struct.new(:rname, :ns, :ta, :exp, :init_exp)
      def absolute_name
        ns.absolute_name(rname)
      end

      def vconst_refs
        [exp, init_exp].reject(&:nil?).flat_map(&:vconst_refs)
      end

      def gen_flat(src_set, dest_set)
        exp.blame_side_effect
        flat_ta = ta && ta.to_flat(src_set, ns)
        flat_init_exp = init_exp && init_exp.to_flat(src_set, ns)
        flat_exp = exp && exp.to_flat(src_set, ns)
        dest_set << Flat::Node.new(absolute_name, flat_ta, flat_exp, flat_init_exp)
      end
    end

    class Output < Struct.new(:ns, :exps, :func_ref, :line_number)
      def rname
        "%output_line#{line_number}"
      end

      def absolute_name
        ns.absolute_name(rname)
      end

      def convert
        exp = FuncCallExp.new(func_ref, exps, false)
        ta = TypeAnnotationType.new(Ref.new('Unit'), [])
        Node.new(rname, ns, ta, exp, nil)
      end
    end

    class Input < Struct.new(:rname, :ns, :ta, :arg_exps, :init_exp, :func_ref)
      def convert
        exp = FuncCallExp.new(func_ref, arg_exps, false)
        Node.new(rname, ns, ta, exp, init_exp)
      end
    end

    class Infix < Struct.new(:ns, :func_ref, :priority, :direction)
      LEFT, RIGHT, NONE = :left, :right, :none

      def absolute_func_name(set)
        func_name = set.func(ns, func_ref).absolute_name
        raise NameError.new(func_ref.to_s) unless func_name
        func_name
      end

      def absolute_priority(position)
        case direction
        when LEFT
          [priority, 1000 - position]
        when RIGHT
          [priority, position]
        when NONE
          [priority, 0]
        end
      end
    end

    class FuncTypeAnnotation < Struct.new(:ret_ta, :arg_tas)
      def to_flat(set, ns)
        flat_arg_tas = arg_tas.map { |ta| ta.to_flat(set, ns) }
        Flat::FuncTypeAnnotation.new(ret_ta.to_flat(set, ns), flat_arg_tas)
      end
    end

    class TypeAnnotationType < Struct.new(:tconst_ref, :arg_tas)
      def to_flat(set, ns)
        ab_tc_name = set.tconst(ns, tconst_ref).absolute_name
        flat_arg_tas = arg_tas.map { |ta| ta.to_flat(set, ns) }
        Flat::TypeAnnotationType.new(ab_tc_name, flat_arg_tas)
      end
    end

    class TypeAnnotationVar < Struct.new(:var_str)
      def to_flat(_set, _ns)
        Flat::TypeAnnotationVar.new(var_str)
      end
    end
  end
end
