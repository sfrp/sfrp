require 'spec_helper'
require 'sfrp/raw/set'
require 'sfrp/flat/set'

module SFRP
  describe 'Compiled Flat-Set from Raw-Set' do
    let(:fset) do
      Raw::Set.new do |s|
        ns = Raw::Namespace.new('Main', [])
        s << begin
          a = R.vc_call_e(R.r('1'), [])
          b = R.vc_call_e(R.r('2'), [])
          plus = R.r('+')
          asta = R.r('*')
          exp = R.seq_e([a, b, a, b], [asta, plus, asta])
          Raw::Function.new('f', ns, nil, [], [], exp, nil, false)
        end
        s << begin
          int = R.t(R.r('Int'), [])
          Raw::Function.new('+', ns, int, [a, b], [int, int], nil, 'add', false)
        end
        s << begin
          int = R.t(R.r('Int'), [])
          Raw::Function.new('*', ns, int, ['a', 'b'], [int, int], nil, 'mul', false)
        end
        s << begin
          Raw::PrimTConst.new('Int', ns, 'int', /^([0-9]+)$/, '\1')
        end
        s << Raw::Infix.new(ns, R.r('+'), 6, Raw::Infix::LEFT)
        s << Raw::Infix.new(ns, R.r('*'), 7, Raw::Infix::LEFT)
      end.to_flat
    end

    it 'is compiled correctly' do
      fset # TODO write assertions
    end
  end
end
