require 'sfrp/input/exception'
require 'parslet'

module SFRP
  module Input
    module Parser
      extend self

      def parse(source_file)
        parser = Parser.new
        transformer = Transformer.new
        defs = transformer.apply(parser.parse(source_file.content))
        imports, others = defs.each_with_object([[], []]) do |a, o|
          case a
          when Raw::Import
            o[0] << a
          else
            o[1] << a
          end
        end
        ns = Raw::Namespace.new(source_file.fmodule_uri, imports)
        others.each do |a|
          a.ns = ns
          a.vconsts.each { |b| b.ns = ns } if a.is_a?(Raw::TConst)
        end
        others
      rescue Parslet::ParseFailed => err
        raise ParseError.new(err.message)
      end

      class Parser < Parslet::Parser
        # file
        root(:file)
        rule(:file) {
          (ws? >> listing(toplevel_definition, ws_inc_newline).as(:defs) >> ws?)
          .as(:file)
        }

        # toplevel definition
        rule(:toplevel_definition) {
          import_def |
          init_def |
          prim_type_def | type_def |
          foreign_func_def | function_def | infix_def |
          node_def | input_def | output_def
        }
        rule(:import_def) {
          (str('import') >> ws >> listing(up_ident, str('.')).as(:path) >>
          (ws >> str('as') >> ws >> up_ident.as(:qualifier_name))
          .maybe.as(:as_maybe)).as(:import_def)
        }
        rule(:init_def) {
          (str('init').as(:key) >> ws >> io_func_ref.as(:func_ref) >>
          ws_inline? >>
          str('(') >> ws? >> listing0(exp, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(')')).as(:init_def)
        }
        rule(:prim_type_def) {
          (str('ptype') >> ws >> up_ident.as(:tconst_str) >> ws? >>
          foreign_str.as(:c_type_str) >> ws? >> str('=') >> ws? >>
          str('/') >> match['^/'].repeat(1).as(:rexp) >> str('/') >>
          match['^/'].repeat(1).as(:replace) >> str('/')).as(:prim_type_def)
        }
        rule(:type_def) {
          tconst_params = (str('[') >> ws? >>
          listing0(low_ident, ws? >> str(',') >> ws?).as(:params) >> ws? >>
          str(']')).maybe.as(:params_maybe)
          (str('type') >> ws? >> ((str('+') | str('*')).as(:m) >> ws?)
          .maybe.as(:modifier) >> up_ident.as(:tconst_name) >>
          (ws? >> foreign_str.as(:c_type_str)).maybe.as(:c_type_str_maybe) >>
          tconst_params >> ws? >> str('=') >> ws? >> listing(vconst_def,
          ws? >> str('|') >> ws?).as(:vconst_defs)).as(:type_def)
        }
        rule(:vconst_def) {
          (up_ident.as(:vconst_name) >> (ws? >> foreign_str.as(:c_value_str))
          .maybe.as(:c_value_str_maybe) >>
          (ws_inline? >> str('(') >> ws? >> listing0(type_annot, ws? >>
          str(',') >> ws?).as(:type_annots) >> ws? >> str(')'))
          .maybe.as(:type_annots_maybe)).as(:vconst_def)
        }
        rule(:foreign_func_def) {
          (str('foreign') >> ws >>
          (low_ident | up_ident | op_ident).as(:c_func_name) >> ws >>
          str('as') >> ws >>
          ((str('$').maybe >> low_ident) | op_ident).as(:func_name) >>
          ws_inline? >>
          str('(') >> ws? >> listing0(fixed_type_annot_type, ws? >> str(',') >>
          ws?).as(:params) >> ws? >>
          str(')') >> ws? >> str(':') >> ws? >>
          fixed_type_annot_type.as(:ret_type_annot))
          .as(:foreign_func_def)
        }
        rule(:function_def) {
          param = low_ident.as(:param_name) >> type_annot_maybe.as(:type_annot)
          (((str('$').maybe >> low_ident) | op_ident)
          .as(:func_name) >> ws_inline? >>
          str('(') >> ws? >> listing0(param, ws? >> str(',') >> ws?)
          .as(:params) >> ws? >>
          str(')') >> type_annot_maybe.as(:ret_type_annot) >> ws? >> str('=') >>
          ws? >> exp.as(:exp)).as(:function_def)
        }
        rule(:infix_def) {
          (str('infix') >> (str('l') | str('r')).maybe.as(:direction) >>
          ws >> (op_ref | bq_op_ref).as(:func_ref) >> ws >>
          match['0-9'].repeat(1).as(:priority)).as(:infix_def)
        }
        rule(:node_def) {
          ((str('@') >> low_ident).as(:node_name) >>
          init_def_maybe.as(:init_exp) >> type_annot_maybe.as(:type_annot) >>
          ws? >> str('=') >> ws? >> exp.as(:eval_exp)).as(:node_def)
        }
        rule(:input_def) {
          (str('in') >> ws >> (str('@') >> low_ident).as(:node_name) >>
          init_def_maybe.as(:init_exp) >>
          type_annot_maybe.as(:type_annot) >>
          ws >> str('from') >> ws >> io_func_ref.as(:func_ref) >> ws_inline? >>
          str('(') >> ws? >> listing0(exp, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(')')).as(:input_def)
        }
        rule(:output_def) {
          (str('out').as(:key) >> ws >> io_func_ref.as(:func_ref) >>
          ws_inline? >>
          str('(') >> ws? >> listing(exp, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(')')).as(:output_def)
        }
        rule(:init_def_maybe) {
          (ws? >> str('[') >> ws? >> exp.as(:init_exp) >> ws? >> str(']')).maybe
          .as(:init_def_maybe)
        }
        rule(:foreign_str) {
          (str('{') >> match['^}'].repeat(1).as(:str) >> str('}'))
          .as(:foreign_str)
        }

        # type annotation
        rule(:type_annot_maybe) {
          (ws? >> str(':') >> ws? >> type_annot).maybe.as(:type_annot_maybe)
        }
        rule(:type_annot) {
          type_annot_type | type_annot_var
        }
        rule(:type_annot_type) {
          whole = tconst_ref.as(:tconst_ref) >> (ws_inline? >> str('[') >>
          ws? >> listing0(type_annot, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(']')).maybe.as(:args_maybe)
          whole.as(:type_annot_type)
        }
        rule(:fixed_type_annot_type) {
          whole = tconst_ref.as(:tconst_ref) >> (ws_inline? >> str('[') >>
          ws? >> listing0(fixed_type_annot_type, ws? >> str(',') >>
          ws?).as(:args) >> ws? >> str(']')).maybe.as(:args_maybe)
          whole.as(:type_annot_type)
        }
        rule(:type_annot_var) {
          low_ident.as(:type_annot_var)
        }

        # expression
        rule(:exp) {
          seq_exp
        }
        rule(:where_exp) {
          whole = seq_exp.as(:exp) >> ws >> str('where') >> ws >>
          dynamic { |s, _|
            indent = str("\s").repeat(s.line_and_column[1] - 1)
            listing(assign, ws_inline? >> newline >> indent).as(:assignments)
          }
          whole.as(:where_exp)
        }
        rule(:seq_exp) {
          whole = single_exp.as(:exp) >> (ws? >>
          (op_ref | bq_op_ref).as(:func_ref) >> ws? >>
          single_exp.as(:exp)).repeat
          whole.as(:seq_exp)
        }
        rule(:single_exp) {
          # controling
          if_exp | let_exp | match_exp | unary_op_exp |
          # calling
          func_call_exp | io_func_call_exp |
          vc_call_exp_with_paren | vc_call_exp_without_paren |
          tuple_exp |
          # reference
          node_last_ref_exp | node_current_ref_exp | var_ref_exp |
          # parenthesis
          str('(') >> ws? >> exp >> ws? >> str(')')
        }

        # ref exp
        rule(:node_last_ref_exp) {
          node_last_ref.as(:node_ref).as(:node_last_ref_exp)
        }
        rule(:node_current_ref_exp) {
          node_current_ref.as(:node_ref).as(:node_current_ref_exp)
        }
        rule(:var_ref_exp) {
          low_ident.as(:var_ref_exp)
        }

        # call exp
        rule(:func_call_exp) {
          whole = func_ref.as(:func_ref) >> ws_inline? >>
          paren(listing0(exp, ws? >> str(',') >> ws?)).as(:args)
          whole.as(:func_call_exp)
        }
        rule(:io_func_call_exp) {
          whole = io_func_ref.as(:func_ref) >> ws_inline? >>
          paren(listing0(exp, ws? >> str(',') >> ws?)).as(:args)
          whole.as(:io_func_call_exp)
        }
        rule(:vc_call_exp_with_paren) {
          whole = vconst_ref.as(:vconst_ref) >> ws_inline? >> str('(') >> ws? >>
          listing0(exp, ws? >> str(',') >> ws?).as(:args) >> ws? >> str(')')
          whole.as(:vc_call_exp_with_paren)
        }
        rule(:vc_call_exp_without_paren) {
          vconst_ref.as(:vconst_ref).as(:vc_call_exp_without_paren)
        }
        rule(:tuple_exp) {
          whole = str('(') >> ws? >>
          listing2(exp, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(')')
          whole.as(:tuple_exp)
        }

        # if exp
        rule(:if_exp) {
          whole = str('if') >> ws >> exp.as(:cond_exp) >> ws >> str('then') >>
          ws >> exp.as(:then_exp) >> ws >> str('else') >> ws >>
          exp.as(:else_exp)
          whole.as(:if_exp)
        }

        # let exp
        rule(:let_exp) {
          whole = str('let') >> ws >> dynamic { |s, _|
            indent = str("\s").repeat(s.line_and_column[1] - 1)
            listing(assign, ws_inline? >> newline >> indent).as(:assignments)
          } >> ws >> str('in') >> ws >> exp.as(:in_exp)
          whole.as(:let_exp)
        }
        rule(:assign) {
          whole = pattern.as(:left_pattern) >> ws? >> str('=') >> ws? >>
          (where_exp | exp).as(:right_exp)
          whole.as(:assign)
        }

        # match exp
        rule(:match_exp) {
          whole = str('case') >> ws >> exp.as(:left_exp) >> ws >> str('of') >>
          ws? >> dynamic { |s, _|
            indent = str("\s").repeat(s.line_and_column[1] - 1)
            listing(match_case, ws_inline? >> newline >> indent).as(:cases)
          }
          whole.as(:match_exp)
        }
        rule(:match_case) {
          (
            pattern.as(:pattern) >> ws? >> str('->') >> ws? >> exp.as(:exp)
          ).as(:match_case)
        }

        # unary op exp
        rule(:unary_op_exp) {
          (op_ref.as(:func_ref) >> ws? >> single_exp.as(:exp))
          .as(:unary_op_exp)
        }

        # pattern
        rule(:pattern) {
          vc_pattern_with_paren | vc_pattern_without_paren |
          tuple_pattern | any_pattern
        }
        rule(:vc_pattern_with_paren) {
          whole = vconst_ref.as(:vconst_ref) >> ws_inline? >> str('(') >> ws? >>
          listing0(pattern, ws? >> str(',') >> ws?).as(:args) >> ws? >>
          str(')') >> (ws? >> as).maybe.as(:var_ref)
          whole.as(:vc_pattern_with_paren)
        }
        rule(:vc_pattern_without_paren) {
          whole = vconst_ref.as(:vconst_ref) >> (ws? >> as).maybe.as(:var_ref)
          whole.as(:vc_pattern_without_paren)
        }
        rule(:tuple_pattern) {
          whole = str('(') >> ws? >>
          listing2(pattern, ws? >> str(',') >> ws?).as(:args) >>
          ws? >> str(')') >> (ws? >> as).maybe.as(:var_ref)
          whole.as(:tuple_pattern)
        }
        rule(:any_pattern) {
          low_ident.as(:any_pattern)
        }
        rule(:as) {
          (str('as') >> ws? >> low_ident.as(:str)).as(:as)
        }

        # reference
        rule(:node_last_ref) {
          qualifier >> str('@') >> (str('@') >> low_ident).as(:name)
        }
        rule(:node_current_ref) {
          qualifier >> (str('@') >> low_ident).as(:name)
        }
        rule(:func_ref) {
          qualifier >> low_ident.as(:name)
        }
        rule(:io_func_ref) {
          qualifier >> (str('$') >> low_ident).as(:name)
        }
        rule(:op_ref) {
          qualifier >> op_ident.as(:name)
        }
        rule(:bq_op_ref) {
          str('`') >> qualifier >> low_ident.as(:name) >> str('`')
        }
        rule(:vconst_ref) {
          qualifier >> (up_ident | num_ident).as(:name)
        }
        rule(:tconst_ref) {
          qualifier >> up_ident.as(:name)
        }
        rule(:qualifier) {
          (up_ident.as(:str) >> str('.')).maybe.as(:qualifier)
        }

        rule(:num_ident) { match['0-9'] >> match['a-zA-Z0-9'].repeat }
        rule(:op_ident) {
          usable_chars = "!#%&*+./<=>?\\^|-~'".chars
          usable_chars.map { |c| str(c) }.reduce { |x, y| x | y }.repeat(1)
        }
        rule(:low_ident) { match['a-z_'] >> match['a-zA-Z0-9_'].repeat }
        rule(:up_ident) { match['A-Z'] >> match['a-zA-Z0-9_'].repeat }
        rule(:ws) { (str("\s") | str("\n")).repeat(1) }
        rule(:ws?) { ws.maybe }
        rule(:ws_inline) { str("\s").repeat(1) }
        rule(:ws_inline?) { ws_inline.maybe }
        rule(:newline) { str("\n").repeat(1) }
        rule(:ws_inc_newline) { ws_inline? >> newline >> ws? }

        def listing(e, separator)
          (e.as(:e) >> (separator >> e.as(:e)).repeat).as(:listing)
        end

        def listing0(e, separator)
          listing(e, separator).maybe.as(:listing0)
        end

        def listing2(e, separator)
          (e.as(:e) >> (separator >> e.as(:e)).repeat(1)).as(:listing)
        end

        def opt(left_separator, optional_rule)
          (left_separator >> optional_rule.as(:entity)).maybe.as(:opt)
        end

        def paren(rule)
          wrap('(', rule, ')')
        end

        def wrap(lstr, rule, rstr)
          str(lstr) >> ws? >> rule >> ws? >> str(rstr)
        end
      end
    end
  end
end
