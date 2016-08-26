require 'spec_helper'
require 'sfrp/flat/set'
require 'sfrp/poly/set'

module SFRP
  describe 'Compiled Poly-Set from Flat-Set' do
    let(:pset) do
      Flat::Set.new do |s|

        s << begin
          exp = F.nr_e('b', false)
          init_exp = F.call_e('init', [])
          Flat::Node.new('a', F.tv('a'), exp, init_exp)
        end

        s << begin
          exp = F.call_e('ff', [])
          Flat::Node.new('b', F.tv('a'), exp, nil)
        end

        s << begin
          int = F.t('Int', [])
          exp = F.vc_call_e('1', [])
          Flat::Function.new('init', int, [], [], exp, nil)
        end

        s << begin
          int = F.t('Int', [])
          Flat::Function.new('ff', int, [], [], nil, 'ff')
        end

        s.append_output_node_str('a')
      end.to_poly
    end

    it 'is compiled correctly' do
      pset # TODO wirte assertion
    end
  end
end
