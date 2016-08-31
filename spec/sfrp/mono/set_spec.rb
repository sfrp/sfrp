require 'spec_helper'
require 'sfrp/mono/set'
require 'sfrp/low/set'

module SFRP
  describe 'Compiled Low-Set from Mono-Set' do
    let(:lset) do
      set = Mono::Set.new

      # type MaybeInt = JustInt(TInt) | NothingInt
      set << M.type('MaybeInt', ['JustInt', 'NothingInt'])
      set << M.vconst('MaybeInt', 'JustInt', ['Int'])
      set << M.vconst('MaybeInt', 'NothingInt', [])

      # type Pair = Pair(Int, Int)
      set << M.type('Pair', ['Pair'])
      set << M.vconst('Pair', 'Pair', ['Int', 'Int'])

      # type Int{int}
      set << M.type('Int', nil, true, 'int')
      set << M.vconst('Int', '0', [], '0')
      set << M.vconst('Int', '1', [], '1')

      # type X = X1(MabybeInt) | X2(MaybeInt, MaybeInt)
      set << M.type('X', ['X1', 'X2'])
      set << M.vconst('X', 'X1', ['MaybeInt'])
      set << M.vconst('X', 'X2', ['MaybeInt', 'MaybeInt'])

      # type XX = XX(MaybeInt)
      set << M.type('XX', ['XX'])
      set << M.vconst('XX', 'XX', ['MaybeInt'])

      # type STupleIntInt = STupleIntInt(Int, Int)
      set << M.type('STupleIntInt', ['STupleIntInt'], true)
      set << M.vconst('STupleIntInt', 'STupleIntInt', ['Int', 'Int'])

      # func getMaybeInt(){get_maybe_int}
      set << M.func('MaybeInt', 'getMaybeInt') do |f|
        f.ffi_str('get_maybe_int')
      end

      set << M.func('Int', 'id') do |f|
        f.param('Int', 'x')
        f.exp { M.v_e('Int', 'x') }
      end

      set << M.func('Int', 'initialize') do |f|
        f.ffi_str('init_system')
      end

      set << M.func('MaybeInt', 'initialMaybeInt') do |f|
        f.exp { M.vc_call_e('MaybeInt', 'JustInt', M.vc_call_e('Int', '1')) }
      end

      set << M.func('Pair', 'ffiPair') do |f|
        f.ffi_str('ffi_pair')
      end

      # func (arg) = arg of MaybeInt(x) -> Pair(x, x), NothingInt -> (0, 0)
      set << M.func('Pair', 'toPair') do |f|
        f.param('MaybeInt', 'arg')
        f.exp do
          M.match_e('Pair', M.v_e('MaybeInt', 'arg')) do |m|
            m.case(M.pat('MaybeInt', 'JustInt', M.pany('Int', 'x'))) do
              M.vc_call_e('Pair', 'Pair', M.v_e('Int', 'x'), M.v_e('Int', 'x'))
            end
            m.case(M.pref('MaybeInt', 'NothingInt', 'hoge')) do
              zero = M.call_e('Int', 'id', M.vc_call_e('Int', '0'))
              M.vc_call_e('Pair', 'Pair', zero, zero)
            end
            m.case(M.pany('MaybeInt')) do
              M.call_e('Pair', 'ffiPair')
            end
          end
        end
      end

      # func (arg) = arg of VX(x, y) -> VX(y, x)
      set << M.func('X', 'swap') do |f|
        f.param('X', 'arg')
        f.exp do
          M.match_e('X', M.v_e('X', 'arg'))do |m|
            mint = 'MaybeInt'
            m.case(M.pat('X', 'X2', M.pany(mint, 'x'), M.pany(mint, 'y'))) do
              M.vc_call_e('X', 'X2', M.v_e(mint, 'y'), M.v_e(mint, 'x'))
            end
          end
        end
      end

      # node bufNode[1] = getMaybeInt()
      set << M.node('MaybeInt', 'bufNode', 'getMaybeInt', 'initialMaybeInt')

      # node node1 = toPair(bufNode, @bufNode)
      set << M.node('Pair', 'node1', 'toPair', nil) do |n|
        n.c('bufNode')
        n.l('bufNode')
      end

      set.append_output_node_str('node1')
      set.append_init_func_str('initialize')

      set.to_low
    end

    let(:expected) do
      require 'yaml'
      YAML.load_file(File.expand_path('../expected.yml', __FILE__))
    end

    it 'has includes' do
      expect(lset.includes.map(&:to_s)).to contain_exactly(
        *expected['includes']
      )
    end

    it 'has macros' do
      expect(lset.macros.map(&:to_s)).to contain_exactly(
        *expected['macros']
      )
    end

    it 'has typedefs' do
      expect(lset.typedefs.map(&:to_s)).to contain_exactly(
        *expected['typedefs']
      )
    end

    it 'has structs' do
      expect(lset.structs.map(&:to_s)).to contain_exactly(
        *expected['structs'].map(&:chomp)
      )
    end

    it 'has prototypes of the function' do
      expect(lset.functions.map(&:pretty_code_prototype)).to contain_exactly(
        *expected['proto_functions']
      )
    end

    it 'has functions' do
      expected_functions = expected['functions'].map(&:chomp).sort
      actual_functions = lset.functions.map(&:to_s).sort
      actual_functions.zip(expected_functions) do |a, e|
        expect(a).to eql e
      end
    end
  end
end
