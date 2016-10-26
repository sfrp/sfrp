require 'parslet'
require 'sfrp/raw/set'

module SFRP
  module Input
    class Transformer < Parslet::Transform
      rule(:file => subtree(:x)) {
        x[:defs]
      }
      # toplevel definition
      rule(:import_def => subtree(:x)) {
        ab_ns_name = x[:path].map(&:to_s).join('.')
        qualifier_name = x[:as_maybe] && x[:as_maybe][:qualifier_name].to_s
        Raw::Import.new(ab_ns_name, qualifier_name)
      }
      rule(:init_def => subtree(:x)) {
        Raw::Init.new(nil, x[:func_ref], x[:args], x[:key].line_and_column[0])
      }
      rule(:prim_type_def => subtree(:x)) {
        rname = x[:tconst_str].to_s
        native_str = x[:c_type_str]
        pattern = Regexp.new(x[:rexp])
        replace = x[:replace].to_s
        Raw::PrimTConst.new(rname, nil, native_str, pattern, replace)
      }
      rule(:prim_enum_type_def => subtree(:x)) {
        rname = x[:tconst_str].to_s
        vconsts = x[:vconst_defs]
        native_str = x[:c_type_str]
        vconsts.each { |v| v.tconst_rname = rname }
        Raw::TConst.new(rname, nil, [], vconsts, native_str, true)
      }
      rule(:prim_enum_vconst_def => subtree(:x)) {
        rname = x[:vconst_str].to_s
        native_str = x[:c_value_str]
        Raw::VConst.new(rname, nil, nil, native_str, [])
      }
      rule(:type_def => subtree(:x)) {
        rname = x[:tconst_name].to_s
        pstrs = x[:params_maybe] ? x[:params_maybe][:params].map(&:to_s) : []
        vconsts = x[:vconst_defs]
        static = x[:modifier] && x[:modifier][:m].to_s == '+'
        vconsts.each { |v| v.tconst_rname = rname }
        Raw::TConst.new(rname, nil, pstrs, vconsts, nil, static)
      }
      rule(:vconst_def => subtree(:x)) {
        rname = x[:vconst_name].to_s
        ptas = x[:type_annots_maybe] ? x[:type_annots_maybe][:type_annots] : []
        Raw::VConst.new(rname, nil, nil, nil, ptas)
      }
      rule(:foreign_func_def => subtree(:x)) {
        rname = x[:func_name].to_s
        ret_ta = x[:ret_type_annot]
        pstrs = Array.new(x[:params].size)
        ptas = x[:params]
        ffi_str = x[:c_func_name].to_s
        effect = rname[0] == '$'
        Raw::Function.new(rname, nil, ret_ta, pstrs, ptas, nil, ffi_str, effect)
      }
      rule(:function_def => subtree(:x)) {
        rname = x[:func_name].to_s
        ret_ta = x[:ret_type_annot]
        pstrs = x[:params].map { |a| a[:param_name].to_s }
        ptas = x[:params].map { |a| a[:type_annot] }
        exp = x[:exp]
        effect = rname[0] == '$'
        Raw::Function.new(rname, nil, ret_ta, pstrs, ptas, exp, nil, effect)
      }
      rule(:infix_def => subtree(:x)) {
        priority = Integer(x[:priority].to_s)
        direction =
        case x[:direction]
        when 'l' then Raw::Infix::LEFT
        when 'r' then Raw::Infix::RIGHT
        when ''  then Raw::Infix::NONE
        end
        Raw::Infix.new(nil, x[:func_ref], priority, direction)
      }
      rule(:node_def => subtree(:x)) {
        Raw::Node.new(
          x[:node_name].to_s, nil, x[:type_annot], x[:eval_exp], x[:init_exp]
        )
      }
      rule(:input_def => subtree(:x)) {
        Raw::Input.new(
          x[:node_name].to_s, nil, x[:type_annot], x[:args], x[:init_exp],
          x[:func_ref]
        )
      }
      rule(:output_def => subtree(:x)) {
        Raw::Output.new(nil, x[:args], x[:func_ref], x[:key].line_and_column[0])
      }
      rule(:init_def_maybe => subtree(:x)) {
        x && x[:init_exp]
      }
      rule(:foreign_str => subtree(:x)) {
        x[:str].to_s
      }

      # type
      rule(:type_annot_maybe => subtree(:x)) {
        x
      }
      rule(:type_annot_type => subtree(:x)) {
        args = (x[:args_maybe] == nil ? [] : x[:args_maybe][:args])
        Raw::TypeAnnotationType.new(x[:tconst_ref], args)
      }
      rule(:type_annot_tuple => subtree(:x)) {
        tconst_ref = Raw::Ref.new("Tuple#{x[:args].size}")
        Raw::TypeAnnotationType.new(tconst_ref, x[:args])
      }
      rule(:type_annot_var => subtree(:x)){
        Raw::TypeAnnotationVar.new(x.to_s)
      }

      # expression
      rule(:where_exp => subtree(:x)) {
        next x[:exp] if x[:where_clause_maybe].nil?
        Raw::LetExp.new(x[:exp], x[:where_clause_maybe][:assignments])
      }
      rule(:seq_exp => subtree(:x)) {
        next x[:exp] unless x.is_a?(Array)
        exps = x.map { |a| a[:exp] }
        func_refs = x.drop(1).map { |a| a[:func_ref] }
        Raw::SequenceExp.new(exps, func_refs)
      }

      # ref-exp
      rule(:node_last_ref_exp => subtree(:x)) {
        Raw::NodeRefExp.new(x[:node_ref], true)
      }
      rule(:node_current_ref_exp => subtree(:x)) {
        Raw::NodeRefExp.new(x[:node_ref], false)
      }
      rule(:var_ref_exp => subtree(:x)) {
        Raw::VarRefExp.new(x.to_s)
      }

      # call-exp
      rule(:func_call_exp => subtree(:x)) {
        Raw::FuncCallExp.new(x[:func_ref], x[:args], false)
      }
      rule(:io_func_call_exp => subtree(:x)) {
        Raw::FuncCallExp.new(x[:func_ref], x[:args], true)
      }
      rule(:vc_call_exp_with_paren => subtree(:x)) {
        Raw::VConstCallExp.new(x[:vconst_ref], x[:args])
      }
      rule(:vc_call_exp_without_paren => subtree(:x)) {
        Raw::VConstCallExp.new(x[:vconst_ref], [])
      }
      rule(:tuple_exp => subtree(:x)) {
        vconst_ref = Raw::Ref.new("Tuple#{x[:args].size}")
        Raw::VConstCallExp.new(vconst_ref, x[:args])
      }

      # if-exp
      rule(:if_exp => subtree(:x)) {
        Raw::IfExp.new(x[:cond_exp], x[:then_exp], x[:else_exp])
      }

      # let-exp
      rule(:let_exp => subtree(:x)) {
        Raw::LetExp.new(x[:in_exp], x[:assignments])
      }
      rule(:assign => subtree(:x)) {
        Raw::LetExp::Assignment.new(x[:left_pattern], x[:right_exp])
      }

      # match-exp
      rule(:match_exp => subtree(:x)) {
        Raw::MatchExp.new(x[:left_exp], x[:cases])
      }
      rule(:match_case => subtree(:x)) {
        Raw::MatchExp::Case.new(x[:pattern], x[:exp])
      }

      # unary op exp
      rule(:unary_op_exp => subtree(:x)) {
        func_ref = Raw::Ref.new(
          "'" + x[:func_ref].relative_name, x[:func_ref].qualifier_name
        )
        Raw::FuncCallExp.new(func_ref, [x[:exp]], false)
      }

      # pattern
      rule(:any_pattern => simple(:x)) {
        var_str = x.to_s
        Raw::MatchExp::Pattern.new(nil, var_str == '_' ? nil : var_str, [])
      }
      rule(:vc_pattern_with_paren => subtree(:x)) {
        Raw::MatchExp::Pattern.new(x[:vconst_ref], x[:var_ref], x[:args])
      }
      rule(:vc_pattern_without_paren => subtree(:x)) {
        Raw::MatchExp::Pattern.new(x[:vconst_ref], x[:var_ref], [])
      }
      rule(:tuple_pattern => subtree(:x)) {
        vconst_ref = Raw::Ref.new("Tuple#{x[:args].size}")
        Raw::MatchExp::Pattern.new(vconst_ref, x[:var_ref], x[:args])
      }
      rule(:as => subtree(:x)) {
        x[:str].to_s
      }

      # others
      rule(:name => subtree(:n), :qualifier => subtree(:q)) {
        Raw::Ref.new(n.to_s, q && q[:str].to_s)
      }
      rule(:listing => subtree(:x)) {
        (x.is_a?(Array) ? x : [x]).map { |a| a[:e] }
      }
      rule(:listing0 => subtree(:x)) {
        x == nil ? [] : x
      }
      rule(:opt => subtree(:x)) {
        x == nil ? nil : x[:entity]
      }
    end
  end
end
