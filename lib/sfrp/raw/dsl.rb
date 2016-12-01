module SFRP
  module Raw
    extend SFRP::R = self

    def r(rname, qualifier = nil)
      Ref.new(rname, qualifier)
    end

    def t(tconst_ref, args)
      TypeAnnotationType.new(tconst_ref, args)
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

    def nr_e(node_ref, last)
      NodeRefExp.new(node_ref, last)
    end

    def call_e(func_ref, args)
      FuncCallExp.new(func_ref, args)
    end

    def vc_call_e(vconst_ref, args)
      VConstCallExp.new(vconst_ref, args)
    end

    def seq_e(exps, func_refs)
      SequenceExp.new(exps, func_refs)
    end
  end
end
