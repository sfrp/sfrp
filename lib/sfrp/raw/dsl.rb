module SFRP
  module Raw
    extend SFRP::R = self

    def r(rname, qualifier = nil)
      Ref.new(rname, qualifier)
    end

    def t(tconst_ref, args, sp = nil)
      TypeAnnotationType.new(tconst_ref, args, sp)
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

    def nr_e(node_ref, last, sp = nil)
      NodeRefExp.new(node_ref, last, sp)
    end

    def call_e(func_ref, args, sp = nil)
      FuncCallExp.new(func_ref, args, sp)
    end

    def vc_call_e(vconst_ref, args, sp = nil)
      VConstCallExp.new(vconst_ref, args, sp)
    end

    def seq_e(exps, func_refs, sp = nil)
      SequenceExp.new(exps, func_refs, sp)
    end
  end
end
