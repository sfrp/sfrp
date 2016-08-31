module SFRP
  module Flat
    class Function < Struct.new(:str, :ret_ta, :pstrs, :ptas, :exp, :ffi_str, :sp)
      require 'tapp'
      def to_poly(_src_set, dest_set)
        dest_set << P.func(str, ret_ta && ret_ta.to_poly) do |f|
          pstrs.zip(ptas) do |s, ta|
            f.param(s, ta && ta.to_poly)
          end
          f.exp { exp.to_poly } if exp
          f.ffi_str(ffi_str) if ffi_str
        end
      end
    end

    class TConst < Struct.new(:str, :pstrs, :vc_strs, :native_str, :static, :sp)
      def type_annot
        TypeAnnotationType.new(str, pstrs.map { |s| TypeAnnotationVar.new(s) })
      end

      def to_poly(_src_set, dest_set)
        argc = pstrs.size
        dest_set << Poly::TConst.new(str, argc, vc_strs, static, native_str)
      end
    end

    class VConst < Struct.new(:str, :tconst_str, :native_str, :param_tas, :sp)
      def to_poly(src_set, dest_set)
        tconst = src_set.tconst(tconst_str)
        fta = FuncTypeAnnotation.new(tconst.type_annot, param_tas)
        dest_set << Poly::VConst.new(str, tconst.pstrs, fta.to_poly, native_str)
      end
    end

    class Node < Struct.new(:str, :ta, :exp, :init_exp, :sp)
      def to_poly(_src_set, dest_set)
        dest_set << P.node(str, ta && ta.to_poly) do |n|
          collected_node_refs = []
          lifted_exp = exp.lift_node_ref(collected_node_refs)
          collected_node_refs.each do |nr|
            nr.last ? n.l(nr.node_str) : n.c(nr.node_str)
          end
          dest_set << n.eval_func(str, ta && ta.to_poly) do |f|
            f.exp { lifted_exp.to_poly }
            collected_node_refs.each_with_index.map do |_, i|
              f.param("__node_ref_#{i}")
            end
          end
          next if init_exp.nil?
          dest_set << n.init_func(str + '#init', ta && ta.to_poly) do |f|
            f.exp { init_exp.to_poly }
          end
        end
      end
    end

    class FuncTypeAnnotation < Struct.new(:ret_ta, :arg_tas, :sp)
      def to_poly
        Poly::FuncTypeAnnotation.new(ret_ta.to_poly, arg_tas.map(&:to_poly))
      end
    end

    class TypeAnnotationType < Struct.new(:tconst_str, :arg_tas, :sp)
      def to_poly
        P.t(tconst_str, *arg_tas.map(&:to_poly))
      end
    end

    class TypeAnnotationVar < Struct.new(:var_str, :sp)
      def to_poly
        P.tv(var_str)
      end
    end
  end
end
