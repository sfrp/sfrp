require 'spec_helper'
require 'sfrp/input/set'
require 'sfrp/raw/set'

module SFRP
  describe 'Compiled Raw-Set from Input-Set' do
    let(:test_program) do
      File.open(File.expand_path('../parse_test.sfrp', __FILE__), 'r', &:read)
    end
    let(:parsed_) do
      pa = Input::Parser::Parser.new
      tf = Input::Transformer.new
      tf.apply(pa.parse("ptype Int{int} = /1/1/"))
    end
    let(:parsed) do
      pa = Input::Parser::Parser.new
      tf = Input::Transformer.new
      tf.apply(pa.parse(test_program))
    end

    it 'is valid' do
      parsed
    end
  end
end
