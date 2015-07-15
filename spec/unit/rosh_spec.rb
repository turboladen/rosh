require 'rosh'

RSpec.describe Rosh do
  subject(:rosh_class) { described_class }
  before { described_class.reset! }

  describe '.environment' do
    it { is_expected.to respond_to :environment }
  end

  describe '.hosts' do
    it { is_expected.to respond_to :hosts }
  end

  describe '.add_host' do
    it { is_expected.to respond_to :add_host }
  end

  describe '.config' do
    around do |example|
      MemFs.activate!
      example.run
      MemFs.deactivate!
    end

    context '~/.roshrc exists' do
      before do
        ::File.open('.roshrc', 'w') { |f| f.write 'meow' }
        subject.const_set(:DEFAULT_RC_FILE, '.roshrc')
      end

      it 'loads and returns the contents of the file' do
        pending 'Figuring out how to mock files without exceptions'
        expect(subject.config).to eq('meow')
      end
    end
  end
end
