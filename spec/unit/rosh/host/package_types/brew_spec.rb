require 'spec_helper'
require 'rosh/host/package_types/brew'


describe Rosh::Host::PackageTypes::Brew do
  let(:shell) { double 'Rosh::Host::Shell' }

  subject do
    Rosh::Host::PackageTypes::Brew.new('thing', shell)
  end

  describe '#info' do
    let(:output) do
      <<-OUTPUT
thing: stable 2.0.21, HEAD
http://www.monkey.org/~provos/libevent/
/usr/local/Cellar/libevent/2.0.16 (48 files, 1.9M)
/usr/local/Cellar/libevent/2.0.17 (48 files, 1.8M)
/usr/local/Cellar/libevent/2.0.19 (48 files, 1.8M)
/usr/local/Cellar/libevent/2.0.20 (48 files, 1.8M)
/usr/local/Cellar/libevent/2.0.21 (48 files, 1.8M) *
https://github.com/mxcl/homebrew/commits/master/Library/Formula/libevent.rb
==> Options
--enable-manpages
	Install the libevent manpages (requires doxygen)
--universal
	Build a universal binary
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('brew info thing').and_return output
    end

    it 'parses each field and value to a Hash' do
      subject.info.should == {
        package: 'thing',
        spec: 'stable',
        version: '2.0.21, HEAD',
        homepage: 'http://www.monkey.org/~provos/libevent/'
      }
    end
  end
end
