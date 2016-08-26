module SFRP
  module Low
    module DSL
      SFRP::L = self
      extend self

      def include_ab(str)
        Include.new("<#{str}>")
      end

      def include_dq(str)
        Include.new('"' + str + '"')
      end

      def function(name_str, type_str, static = false, &block)
        fp = FuncProxy.new
        block.call(fp) if block
        Function.new(static, name_str, type_str, fp.params, fp.stmts)
      end

      def typedef(str)
        Typedef.new(str)
      end

      def macro(str)
        Macro.new(str)
      end

      def struct(name_str, &block)
        members = []
        block.call(members) if block
        Structure.new('struct', name_str, members)
      end

      def member_structure(kind_str, var_str, &block)
        members = []
        block.call(members) if block
        MemberStructure.new(kind_str, var_str, members)
      end

      def member(str)
        Member.new(str)
      end

      class FuncProxy
        attr_reader :params, :stmts

        def initialize
          @params = []
          @stmts = []
        end

        def append_param(type_str, var_str)
          @params << Function::Param.new(type_str, var_str)
        end

        def <<(stmt)
          @stmts << stmt
        end
      end

      # --------------------------------------------------
      # Statement
      # --------------------------------------------------

      def stmt(line)
        Statement.new(line)
      end

      def while(cond_exp, &block)
        stmts = []
        block.call(stmts) if block
        Block.new('while', cond_exp, stmts)
      end

      def if_stmt(cond_exp, &block)
        stmts = []
        block.call(stmts) if block
        Block.new('if', cond_exp, stmts)
      end

      # --------------------------------------------------
      # Expression (String)
      # --------------------------------------------------

      def call_exp(callee_str, arg_exps)
        "#{callee_str}(#{arg_exps.map { |e| "(#{e})" }.join(', ')})"
      end

      def if_chain_exp(&block)
        ip = IfChainProxy.new
        block.call(ip)
        ip.to_exp
      end

      class IfChainProxy
        def initialize
          @finised = false
          @cond_exps = []
          @exps = []
        end

        def finish(exp)
          return if @finished
          @exps << exp
          @finised = true
        end

        def append_case(cond_exp, exp)
          return if @finised
          @cond_exps << cond_exp
          @exps << exp
        end

        def to_exp
          raise if @exps.empty?
          @cond_exps.pop unless @finised
          @finised = true
          xs = @cond_exps.zip(@exps).map { |ce, e| "(#{ce}) ? (#{e}) :" }
          last = "(#{@exps[-1]})"
          (xs + [last]).join(' ')
        end
      end
    end
  end
end
