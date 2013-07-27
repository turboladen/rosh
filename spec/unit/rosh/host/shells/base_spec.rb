require 'spec_helper'
require 'rosh/host/shells/base'


describe Rosh::Host::Shells::Base do
  subject do
    Rosh::Host::Shells::Base.new
  end

  its(:history) { should eq [] }

  describe '#check_state_first?' do
    it 'defaults to false' do
      subject.check_state_first?.should be_false
    end
  end

  describe '#check_state_first=' do
    it 'toggles the setting' do
      expect {
        subject.check_state_first = true
      }.to change { subject.check_state_first? }.
        from(false).to(true)
    end
  end
end
