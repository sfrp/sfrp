module SFRP
  module Flat
    extend SFRP::F = self

    def t(tconst_str, args, sp = nil)
      TypeAnnotationType.new(tconst_str, args, sp)
    end

    def tv(var_str, sp = nil)
      TypeAnnotationVar.new(var_str, sp)
    end

    def ft(ret_t, arg_ts)
      FuncTypeAnnotation.new(ret_t, arg_ts)
    end

    def v_e(var_str, sp = nil)
      VarRefExp.new(var_str, sp)
    end

    def nr_e(node_str, last, sp = nil)
      NodeRefExp.new(node_str, last, sp)
    end

    def call_e(func_str, args, sp = nil)
      FuncCallExp.new(func_str, args, sp)
    end

    def vc_call_e(vconst_str, args, sp = nil)
      VConstCallExp.new(vconst_str, args, sp)
    end
  end
end
