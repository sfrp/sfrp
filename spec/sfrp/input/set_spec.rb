require 'spec_helper'
require 'sfrp/input/set'
require 'sfrp/raw/set'

module SFRP
  describe 'Compiled Raw-Set from Input-Set' do
    let(:test_program) do
      File.open(File.expand_path('../parse_test.sfrp', __FILE__), 'r', &:read)
    end
    let(:parser) do
      Input::Parser::Parser.new
    end

    it 'is valid' do
      expect(parser).to parse(test_program)
    end
  end
end
