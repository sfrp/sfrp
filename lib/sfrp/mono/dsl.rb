module SFRP
  module Mono
    module DSL
      extend SFRP::M = self

      def type(type_str, vconst_strs = nil, static = false, native_str = nil)
        Type.new(type_str, vconst_strs, static, native_str)
      end

      def vconst(type_str, vconst_str, arg_type_strs, native_str = nil)
        VConst.new(vconst_str, type_str, arg_type_strs, native_str)
      end

      def node(type_str, node_str, eval_func_str, init_func_str = nil, &block)
        px = NodeDepProxy.new
        block.call(px) if block
        Node.new(node_str, type_str, px.to_a, eval_func_str, init_func_str)
      end

      def func(type_str, func_str, &block)
        fp = FuncProxy.new
        block.call(fp) if block
        ftype = fp.ftype(type_str)
        Function.new(func_str, fp.param_strs, ftype, fp.exp, fp.ffi_str)
      end

      def match_e(type_str, left_exp, &block)
        cp = CaseProxy.new
        block.call(cp) if block
        MatchExp.new(type_str, left_exp, cp.to_a)
      end

      def call_e(type_str, func_str, *arg_exps)
        FuncCallExp.new(type_str, func_str, arg_exps)
      end

      def vc_call_e(type_str, vconst_str, *arg_exps)
        VConstCallExp.new(type_str, vconst_str, arg_exps)
      end

      def v_e(type_str, var_str)
        VarRefExp.new(type_str, var_str)
      end

      def pat(type_str, vconst_str, *arg_patterns)
        Pattern.new(type_str, vconst_str, nil, arg_patterns)
      end

      def pref(type_str, vconst_str, ref_var_str, *arg_patterns)
        Pattern.new(type_str, vconst_str, ref_var_str, arg_patterns)
      end

      def pany(type_str, ref_var_str = nil)
        Pattern.new(type_str, nil, ref_var_str, [])
      end

      class NodeDepProxy
        def initialize
          @node_refs = []
        end

        def l(node_str)
          @node_refs << Node::NodeRef.new(node_str, true)
        end

        def c(node_str)
          @node_refs << Node::NodeRef.new(node_str, false)
        end

        def to_a
          @node_refs
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

      class FuncProxy
        def initialize
          @param_type_strs = []
          @param_strs = []
        end

        def param(type_str, param_str)
          @param_type_strs << type_str
          @param_strs << param_str
        end

        def exp(&exp_block)
          @exp = exp_block.call if exp_block
          @exp
        end

        def ffi_str(str = nil)
          @ffi_str = str if str
          @ffi_str
        end

        def param_strs
          @param_strs
        end

        def ftype(return_type_str)
          Function::FType.new(@param_type_strs, return_type_str)
        end
      end
    end
  end
end
