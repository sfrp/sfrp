module SFRP
  module Poly
    module DSL
      extend SFRP::P = self

      def tconst(tconst_str, var_strs, static, native_str, infinite, &block)
        tp = TConstProxy.new(tconst_str, var_strs, infinite)
        block.call(tp) if block
        argc = var_strs.size
        TConst.new(tconst_str, argc, tp.vconst_strs, static, native_str)
      end

      def func(func_str, ret_type_annot = nil, &block)
        fp = FuncProxy.new(func_str, ret_type_annot)
        block.call(fp) if block
        fp.to_func
      end

      def node(node_str, type_annot = nil, &block)
        np = NodeProxy.new(node_str, type_annot)
        block.call(np) if block
        np.to_node
      end

      def t(tconst_str, *args)
        TypeAnnotationType.new(tconst_str, args)
      end

      def tv(var_str)
        TypeAnnotationVar.new(var_str)
      end

      def match_e(left_exp, &block)
        cp = CaseProxy.new
        block.call(cp) if block
        MatchExp.new(left_exp, cp.to_a)
      end

      def call_e(func_str, *arg_exps)
        FuncCallExp.new(func_str, arg_exps)
      end

      def vc_call_e(vconst_str, *arg_exps)
        VConstCallExp.new(vconst_str, arg_exps)
      end

      def v_e(var_str)
        VarRefExp.new(var_str)
      end

      def pat(vconst_str, *arg_patterns)
        Pattern.new(vconst_str, nil, arg_patterns)
      end

      def pref(vconst_str, ref_var_str, *arg_patterns)
        Pattern.new(vconst_str, ref_var_str, arg_patterns)
      end

      def pany(ref_var_str = nil)
        Pattern.new(nil, ref_var_str, [])
      end

      class TConstProxy
        def initialize(tconst_str, var_strs, infinite)
          args = var_strs.map { |v| TypeAnnotationVar.new(v) }
          @ret_type_annot = TypeAnnotationType.new(tconst_str, args)
          @var_strs = var_strs
          @infinite = infinite
          @vconst_strs = []
        end

        def vconst(vconst_str, arg_type_annots, native_str = nil)
          ftype_annot = FuncTypeAnnotation.new(@ret_type_annot, arg_type_annots)
          @vconst_strs << vconst_str
          VConst.new(vconst_str, @var_strs, ftype_annot, native_str)
        end

        def vconst_strs
          @infinite ? nil : @vconst_strs
        end
      end

      class FuncProxy
        def initialize(func_str, ret_type_annot = nil)
          @func_str = func_str
          @ret_type_annot = ret_type_annot || DSL.tv('%a0')
          @param_strs = []
          @type_annots = []
        end

        def param(param_str, type_annot = nil)
          @param_strs << param_str
          @type_annots << (type_annot || DSL.tv('%a' + @param_strs.size.to_s))
        end

        def ffi_str(str)
          @ffi_str = str
        end

        def exp(&block)
          @exp = block.call
        end

        def to_func
          ftype_annot = FuncTypeAnnotation.new(@ret_type_annot, @type_annots)
          Function.new(@func_str, @param_strs, ftype_annot, @exp, @ffi_str)
        end
      end

      class NodeProxy
        def initialize(node_str, type_annot)
          @node_str = node_str
          @type_annot = type_annot || TypeAnnotationVar.new('%a0')
          @node_refs = []
          @type_annots = []
        end

        def c(node_str)
          dep(node_str, false)
        end

        def l(node_str)
          dep(node_str, true)
        end

        def dep(node_str, last)
          @node_refs << Node::NodeRef.new(node_str, last)
          @type_annots << TypeAnnotationVar.new('%a' + @node_refs.size.to_s)
        end

        def eval_func(func_str, ret_type_annot = nil, &block)
          @eval_func_str = func_str
          DSL.func(func_str, ret_type_annot, &block)
        end

        def init_func(func_str, ret_type_annot = nil, &block)
          @init_func_str = func_str
          DSL.func(func_str, ret_type_annot, &block)
        end

        def eval_func_str(func_str)
          @eval_func_str = func_str
        end

        def init_func_str(func_str)
          @init_func_str = func_str
        end

        def to_node
          a = @node_refs.size.times.map { |i| TypeAnnotationVar.new("a#{i}") }
          annot = FuncTypeAnnotation.new(@type_annot, a)
          Node.new(@node_str, @node_refs, annot, @eval_func_str, @init_func_str)
        end
      end

      class CaseProxy
        def initialize
          @cases = []
        end

        def case(pattern, &exp_block)
          @cases << MatchExp::Case.new(pattern, exp_block.call)
        end

        def to_a
          @cases
        end
      end
    end
  end
end
