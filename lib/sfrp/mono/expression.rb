module SFRP
  module Mono
    class Exp
      attr_reader :type_str

      def ==(other)
        comp == other.comp
      end
    end

    class MatchExp < Exp
      Case = Struct.new(:pattern, :exp)

      def initialize(type_str, left_exp, cases, id = nil)
        @type_str = type_str
        @left_exp = left_exp
        @cases = cases
        @id = id
      end

      def comp
        [@type_str, @left_exp, @cases]
      end

      # Note that the expression this returns is not wrapped by ().
      def to_low(set, env)
        check_completeness(set)
        tmp_var_str = env.new_var(@left_exp.type_str)
        left_let_exp = "#{tmp_var_str} = #{@left_exp.to_low(set, env)}"
        case_exp = L.if_chain_exp do |i|
          @cases.each do |c|
            cond_exps = c.pattern.low_cond_exps(set, tmp_var_str)
            let_exps = c.pattern.low_let_exps(set, tmp_var_str, env)
            exp = (let_exps + [c.exp.to_low(set, env)]).join(', ')
            i.finish(exp) if cond_exps.empty?
            i.append_case(cond_exps.join(' && '), exp)
          end
        end
        "#{left_let_exp}, #{case_exp}"
      end

      def check_completeness(set)
        set.type(@left_exp.type_str).all_pattern_examples(set).each do |exam|
          unless @cases.any? { |c| c.pattern.accept?(exam) }
            raise IncompleteMatchExpError.new
          end
        end
      end

      def memory(set)
        m = @cases.map { |c| c.exp.memory(set) }.reduce { |a, b| a.or(b) }
        @left_exp.memory(set).and(m)
      end
    end

    class FuncCallExp < Exp
      def initialize(type_str, func_str, arg_exps, id = nil)
        @type_str = type_str
        @func_str = func_str
        @arg_exps = arg_exps
        @id = id
      end

      def comp
        [@type_str, @func_str, @arg_exps]
      end

      def to_low(set, env)
        low_arg_exps = @arg_exps.map { |e| e.to_low(set, env) }
        set.func(@func_str).low_call_exp_in_exp(set, env, low_arg_exps)
      end

      def memory(set)
        @arg_exps.reduce(set.func(@func_str).memory(set)) do |m, e|
          m.and(e.memory(set))
        end
      end
    end

    class VConstCallExp < Exp
      def initialize(type_str, vconst_str, arg_exps, id = nil)
        @type_str = type_str
        @vconst_str = vconst_str
        @arg_exps = arg_exps
        @id = id
      end

      def comp
        [@type_str, @vconst_strs, @arg_exps]
      end

      def to_low(set, env)
        low_arg_exps = @arg_exps.map { |e| e.to_low(set, env) }
        set.vconst(@vconst_str).low_constructor_call_exp(low_arg_exps)
      end

      def memory(set)
        @arg_exps.reduce(Memory.one(@type_str)) do |m, e|
          m.and(e.memory(set))
        end
      end
    end

    class VarRefExp < Exp
      def initialize(type_str, var_str, id = nil)
        @type_str = type_str
        @var_str = var_str
        @id = id
      end

      def comp
        [@type_str, @var_str]
      end

      def to_low(_set, _env)
        @var_str
      end

      def memory(_set)
        Memory.empty
      end
    end
  end
end
