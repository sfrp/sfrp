module SFRP
  module Flat
    extend SFRP::F = self

    def t(tconst_str, args)
      TypeAnnotationType.new(tconst_str, args)
    end

    def tv(var_str)
      TypeAnnotationVar.new(var_str)
    end

    def ft(ret_t, arg_ts)
      FuncTypeAnnotation.new(ret_t, arg_ts)
    end

    def v_e(var_str)
      VarRefExp.new(var_str)
    end

    def nr_e(node_str, last)
      NodeRefExp.new(node_str, last)
    end

    def call_e(func_str, args)
      FuncCallExp.new(func_str, args)
    end

    def vc_call_e(vconst_str, args)
      VConstCallExp.new(vconst_str, args)
    end
  end
end
