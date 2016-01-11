require 'spec_helper'
describe 'pythonel' do

  context 'with defaults for all parameters' do
    it { should contain_class('pythonel') }
  end
end
