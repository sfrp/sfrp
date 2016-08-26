require 'spec_helper'
require 'sfrp/poly/set'
require 'sfrp/mono/set'

module SFRP
  describe do
    def define_maybe(set)
      # type Maybe[a] = Just(a) | Nothing
      set << P.tconst('Maybe', ['a'], false, nil, false) do |t|
        set << t.vconst('Just', [P.tv('a')])
        set << t.vconst('Nothing', [])
      end
    end

    def define_prims(set)
      # type Int{int}
      set << P.tconst('Int', [], true, 'int', true) do |t|
        set << t.vconst('1', [], '1')
      end

      # type Float{float}
      set << P.tconst('Float', [], true, 'float', true) do |t|
        set << t.vconst('1.0', [], '1.0f')
      end
    end

    def define_id(set)
      # fun id(x) = x
      set << P.func('id') do |f|
        f.param('x')
        f.exp { P.v_e('x') }
      end
    end

    describe 'Compiled Mono-Set from Poly-Set' do
      let(:mset) do
        set = Poly::Set.new

        define_maybe(set)
        define_prims(set)
        define_id(set)

        # fun getOrElse(m : Maybe[a], x : a) : a =
        #   m of Just(y) -> y, Nothing -> x
        set << P.func('getOrElse', P.tv('a')) do |f|
          f.param('m', P.t('Maybe', P.tv('a')))
          f.param('x', P.tv('a'))
          f.exp do
            P.match_e P.v_e('m') do |m|
              m.case P.pat('Just', P.pany('y')) do
                P.v_e('y')
              end
              m.case P.pref('Nothing', 'z') do
                P.v_e('x')
              end
            end
          end
        end

        # @const1 = 1
        set << P.node('const1') do |n|
          set << n.eval_func('const1') do |f|
            f.exp { P.call_e('id', P.vc_call_e('1')) }
          end
        end

        # @const1f = 1.0
        set << P.node('const1f') do |n|
          set << n.eval_func('const1f') do |f|
            f.exp { P.vc_call_e('1.0') }
          end
          n.init_func_str('const1f')
        end

        # in @intEventInput{int_input}
        set << P.node('intEventInput') do |n|
          set << n.eval_func('intEventInput', P.t('Maybe', P.t('Int'))) do |f|
            f.ffi_str('int_input')
          end
        end

        # in @floatEventInput{float_input}
        set << P.node('floatEventInput') do |n|
          type_annot = P.t('Maybe', P.t('Float'))
          set << n.eval_func('floatEventInput', type_annot) do |f|
            f.ffi_str('float_input')
          end
        end

        # @nodeA = getOrElse(@intEventInput, @const1)
        set << P.node('nodeA') do |n|
          n.c('intEventInput')
          n.c('const1')
          n.eval_func_str('getOrElse')
          set << n.init_func('const1p') do |f|
            f.exp { P.vc_call_e('1') }
          end
        end

        # @nodeB = getOrElse(@floatEventInput, @const1f)
        set << P.node('nodeB') do |n|
          n.c('floatEventInput')
          n.l('const1f')
          n.eval_func_str('getOrElse')
        end

        set.append_init_func_str('const1')
        set.append_output_node_str('nodeA')
        set.append_output_node_str('nodeB')

        set.to_mono
      end

      let(:tn) do
        {
          'Int'            => 'Tdbac6zj10nxdw8xn2685',
          '1'              => 'Vak3k1f5x3ru64v23ddxo',
          'Float'          => 'Tdol7n8wg95lij6rzba37',
          '1.0'            => 'Vgd6wjf0djtw07gffly24',
          'Maybe[Int]'     => 'T1vln6in9rw26e0oi25tr',
          'Just[Int]'      => 'V267hxr1z5484l2obo663',
          'Nothing[Int]'   => 'V3xq78u7xhmdqdujsb6jg',
          'Maybe[Float]'   => 'T42ehv13rimthj4vjuw82',
          'Just[Float]'    => 'Vrop52fzho740v9tsltiw',
          'Nothing[Float]' => 'V25o2b9281sk5e1a01hwk'
        }
      end

      let(:nn) do
        {
          'const1'          => 'Napz6tziasvc3wsva7uov',
          'const1f'         => 'Nay5c9siqvwjrt17nbhi7',
          'intEventInput'   => 'N75e1fe4ly80ewfy5he9o',
          'floatEventInput' => 'N4hir3j06phk4qgum8mzq',
          'nodeA'           => 'N41pxec9xx86xsu72arao',
          'nodeB'           => 'N7z0xlt28om41dd3woeo2',
        }
      end

      let(:fn) do
        {
          'const1'           => 'F7op98r2iqkw8315rmrqy',
          'const1p'          => 'Fbklzqgjeljjjfzp2dz1p',
          'const1f'          => 'Fas5dh5k278eyt0v8zxta',
          'intEventInput'    => 'Fcdjtu42izdz9j034zrq5',
          'floatEventInput'  => 'Fb5zku91p46q56qxlthw8',
          'getOrElse[Int]'   => 'F5tfjznkktzudbvf3y27c',
          'getOrElse[Float]' => 'F3syi296xo0a73js0soxt',
          'id[Int]'          => 'Fe3mll7ofsdrbjhj24qsy',
        }
      end

      it 'has types' do
        expect(mset.types).to contain_exactly(
          M.type(tn['Int'], nil, true, 'int'),
          M.type(tn['Float'], nil, true, 'float'),
          M.type(tn['Maybe[Int]'], [tn['Just[Int]'], tn['Nothing[Int]']]),
          M.type(tn['Maybe[Float]'], [tn['Just[Float]'], tn['Nothing[Float]']])
        )
      end

      it 'has vconsts' do
        expect(mset.vconsts).to contain_exactly(
          M.vconst(tn['Maybe[Int]'], tn['Just[Int]'], [tn['Int']]),
          M.vconst(tn['Maybe[Int]'], tn['Nothing[Int]'], []),
          M.vconst(tn['Maybe[Float]'], tn['Just[Float]'], [tn['Float']]),
          M.vconst(tn['Maybe[Float]'], tn['Nothing[Float]'], []),
          M.vconst(tn['Int'], tn['1'], [], '1'),
          M.vconst(tn['Float'], tn['1.0'], [], '1.0f'),
        )
      end

      it 'has nodes' do
        expect(mset.nodes).to contain_exactly(
          M.node(tn['Int'], nn['const1'], fn['const1']),
          M.node(tn['Float'], nn['const1f'], fn['const1f'], fn['const1f']),
          M.node(tn['Maybe[Int]'], nn['intEventInput'], fn['intEventInput']),
          M.node(tn['Maybe[Float]'], nn['floatEventInput'], fn['floatEventInput']),
          M.node(tn['Int'], nn['nodeA'], fn['getOrElse[Int]'], fn['const1p']) do |n|
            n.c nn['intEventInput']
            n.c nn['const1']
          end,
          M.node(tn['Float'], nn['nodeB'], fn['getOrElse[Float]']) do |n|
            n.c nn['floatEventInput']
            n.l nn['const1f']
          end,
        )
      end

      it 'has funcs' do
        funcs = [
          M.func(tn['Int'], fn['const1']) do |f|
            f.exp do
              M.call_e(tn['Int'], fn['id[Int]'], M.vc_call_e(tn['Int'], tn['1']))
            end
          end,
          M.func(tn['Int'], fn['const1p']) do |f|
            f.exp { M.vc_call_e(tn['Int'], tn['1']) }
          end,
          M.func(tn['Float'], fn['const1f']) do |f|
            f.exp { M.vc_call_e(tn['Float'], tn['1.0']) }
          end,
          M.func(tn['Maybe[Int]'], fn['intEventInput']) do |f|
            f.ffi_str('int_input')
          end,
          M.func(tn['Maybe[Float]'], fn['floatEventInput']) do |f|
            f.ffi_str('float_input')
          end,
          M.func(tn['Int'], fn['getOrElse[Int]']) do |f|
            f.param(tn['Maybe[Int]'], 'm')
            f.param(tn['Int'], 'x')
            f.exp do
              M.match_e(tn['Int'], M.v_e(tn['Maybe[Int]'], 'm')) do |m|
                m.case M.pat(tn['Maybe[Int]'], tn['Just[Int]'], M.pany(tn['Int'], 'y')) do
                  M.v_e(tn['Int'], 'y')
                end
                m.case M.pref(tn['Maybe[Int]'], tn['Nothing[Int]'], 'z') do
                  M.v_e(tn['Int'], 'x')
                end
              end
            end
          end,
          M.func(tn['Float'], fn['getOrElse[Float]']) do |f|
            f.param(tn['Maybe[Float]'], 'm')
            f.param(tn['Float'], 'x')
            f.exp do
              M.match_e(tn['Float'], M.v_e(tn['Maybe[Float]'], 'm')) do |m|
                m.case M.pat(tn['Maybe[Float]'], tn['Just[Float]'], M.pany(tn['Float'], 'y')) do
                  M.v_e(tn['Float'], 'y')
                end
                m.case M.pref(tn['Maybe[Float]'], tn['Nothing[Float]'], 'z') do
                  M.v_e(tn['Float'], 'x')
                end
              end
            end
          end,
          M.func(tn['Int'], fn['id[Int]']) do |f|
            f.param(tn['Int'], 'x')
            f.exp { M.v_e(tn['Int'], 'x') }
          end,
        ]
        expect(mset.funcs).to contain_exactly(*funcs)
      end
    end

    describe 'Poly-Set including undeterminable type var' do
      let(:pset) do
        set = Poly::Set.new

        define_maybe(set)

        set << P.node('node') do |n|
          set << n.eval_func('nothing') do |f|
            f.exp { P.vc_call_e('Nothing') }
          end
        end

        set
      end

      it 'raises UndeterminableTypeError' do
        err_msg = 'undeterminable type Maybe[a0]'
        expect { pset.to_mono }.to raise_error(
          Poly::UndeterminableTypeError, err_msg
        )
      end
    end

    describe 'Poly-Set including ununifyable type var' do
      let(:pset) do
        set = Poly::Set.new

        define_prims(set)

        set << P.node('node', P.t('Float')) do |n|
          set << n.eval_func('one') do |f|
            f.exp { P.vc_call_e('1') }
          end
        end

        set
      end

      it 'raises UnifyError' do
        err_msg = 'cannot unify Int and Float'
        expect { pset.to_mono }.to raise_error(Poly::UnifyError, err_msg)
      end
    end
  end
end
