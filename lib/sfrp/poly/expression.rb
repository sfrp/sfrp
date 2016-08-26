module SFRP
  module Poly
    class MatchExp
      Case = Struct.new(:pattern, :exp)

      def initialize(left_exp, cases, id = nil)
        @left_exp = left_exp
        @cases = cases
        @id = id
      end

      def typing(set, var_env)
        raise if @typing
        left_exp_typing = @left_exp.typing(set, var_env)
        @typing = Typing.new do |t|
          @cases.each do |c|
            new_var_env = var_env.dup
            left_exp_typing.unify(c.pattern.typing(set, new_var_env))
            t.unify(c.exp.typing(set, new_var_env))
          end
        end
      end

      def clone
        cloned_cases = @cases.map { |c| Case.new(c.pattern.clone, c.exp.clone) }
        MatchExp.new(@left_exp.clone, cloned_cases, @id)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@id, @typing) unless @typing.mono?
        mono_type_str = monofier.use_type(@typing)
        M.match_e(mono_type_str, @left_exp.to_mono(monofier)) do |m|
          @cases.each do |c|
            m.case(c.pattern.to_mono(monofier)) { c.exp.to_mono(monofier) }
          end
        end
      end
    end

    class FuncCallExp
      def initialize(func_str, arg_exps, id = nil)
        @func_str = func_str
        @arg_exps = arg_exps
        @id = id
      end

      def typing(set, var_env)
        raise if @typing
        @ftyping = set.func(@func_str).ftyping(set).instance do |ft|
          ft.params.zip(@arg_exps) { |t, e| e.typing(set, var_env).unify(t) }
        end
        @typing = @ftyping.body
      end

      def clone
        FuncCallExp.new(@func_str, @arg_exps.map(&:clone), @id)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@id, @typing) unless @typing.mono?
        mono_func_str = monofier.use_func(@func_str, @ftyping)
        args = @arg_exps.map { |e| e.to_mono(monofier) }
        M.call_e(monofier.use_type(@typing), mono_func_str, *args)
      end
    end

    class VConstCallExp
      def initialize(vconst_str, arg_exps, id = nil)
        @vconst_str = vconst_str
        @arg_exps = arg_exps
        @id = id
      end

      def typing(set, var_env)
        raise if @typing
        @ftyping = set.vconst(@vconst_str).ftyping.instance do |ft|
          ft.params.zip(@arg_exps) { |t, e| e.typing(set, var_env).unify(t) }
        end
        @typing = @ftyping.body
      end

      def clone
        VConstCallExp.new(@vconst_str, @arg_exps.map(&:clone), @id)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@id, @typing) unless @typing.mono?
        mono_vconst_str = monofier.use_vconst(@vconst_str, @typing)
        args = @arg_exps.map { |e| e.to_mono(monofier) }
        M.vc_call_e(monofier.use_type(@typing), mono_vconst_str, *args)
      end
    end

    class VarRefExp
      def initialize(var_str, id = nil)
        @var_str = var_str
        @id = id
      end

      def typing(_set, var_env)
        @typing = var_env[@var_str]
      end

      def clone
        VarRefExp.new(@var_str, @id)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@id, @typing) unless @typing.mono?
        M.v_e(monofier.use_type(@typing), @var_str)
      end
    end

    class Pattern
      def initialize(vconst_str, ref_var_str, patterns, id = nil)
        @vconst_str = vconst_str
        @ref_var_str = ref_var_str
        @patterns = patterns
        @id = id
      end

      def typing(set, var_env)
        raise if @typing
        @typing = Typing.new do |t|
          var_env[@ref_var_str] = t if @ref_var_str
          if @vconst_str
            set.vconst(@vconst_str).ftyping.instance do |ft|
              @patterns.zip(ft.params) do |pat, param_typing|
                pat.typing(set, var_env).unify(param_typing)
              end
              ft.body.unify(t)
            end
          end
        end
      end

      def clone
        Pattern.new(@vconst_str, @ref_var_str, @patterns.map(&:clone), @id)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@id, @typing) unless @typing.mono?
        mono_type_str = monofier.use_type(@typing)
        if @vconst_str
          mono_vconst_str = monofier.use_vconst(@vconst_str, @typing)
          ch = @patterns.map { |pat| pat.to_mono(monofier) }
          M.pref(mono_type_str, mono_vconst_str, @ref_var_str, *ch)
        else
          M.pany(mono_type_str, @ref_var_str)
        end
      end
    end
  end
end
