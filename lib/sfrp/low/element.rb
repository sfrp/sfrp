module SFRP
  module Low
    class Element
      def to_s
        pretty_code
      end
    end

    class Statement < Element
      def initialize(str)
        @str = str
      end

      def pretty_code(indent = 0)
        ('  ' * indent) + @str + ';'
      end
    end

    class Block < Element
      def initialize(kind_str, cond_exp, stmts)
        @kind_str = kind_str
        @cond_exp = cond_exp
        @stmts = stmts
      end

      def pretty_code(indent = 0)
        inner = @stmts.map { |s| s.pretty_code(indent + 1) + "\n" }.join
        space = '  ' * indent
        "#{space}#{@kind_str} (#{@cond_exp}) {\n#{inner}#{space}}"
      end
    end

    class Function < Element
      Param = Struct.new(:type_str, :var_str)

      def initialize(static, name_str, type_str, params, stmts)
        @static = static
        @name_str = name_str
        @type_str = type_str
        @params = params
        @stmts = stmts
      end

      def static?
        @static
      end

      def pretty_code
        inner = @stmts.map { |s| s.pretty_code(1) + "\n" }.join
        param = @params.map { |pa| "#{pa.type_str} #{pa.var_str}" }.join(', ')
        "#{@type_str} #{@name_str}(#{param}) {\n#{inner}}"
      end

      def pretty_code_prototype
        "#{@type_str} #{@name_str}(#{@params.map(&:type_str).join(', ')});"
      end
    end

    class Structure < Element
      def initialize(kind_str, name_str, members)
        @kind_str = kind_str
        @name_str = name_str
        @members = members
      end

      def pretty_code
        inner = @members.map { |m| m.pretty_code(1) + "\n" }.join
        "#{@kind_str} #{@name_str} {\n#{inner}};"
      end
    end

    class MemberStructure < Element
      def initialize(kind_str, var_str, members)
        @kind_str = kind_str
        @var_str = var_str
        @members = members
      end

      def pretty_code(indent = 0)
        inner = @members.map { |m| m.pretty_code(indent + 1) + "\n" }.join
        space = '  ' * indent
        "#{space}#{@kind_str} {\n#{inner}#{space}} #{@var_str};"
      end
    end

    class Member < Element
      def initialize(str)
        @str = str
      end

      def pretty_code(indent = 0)
        '  ' * indent + @str + ';'
      end
    end

    class Macro < Element
      def initialize(str)
        @str = str
      end

      def pretty_code
        "#define #{@str}"
      end
    end

    class Typedef < Element
      def initialize(str)
        @str = str
      end

      def pretty_code
        "typedef #{@str};"
      end
    end

    class Include < Element
      def initialize(str)
        @str = str
      end

      def pretty_code
        "#include #{@str}"
      end
    end
  end
end
