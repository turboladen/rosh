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

  describe 'installed?' do
    before do
      shell.should_receive(:exec).with('brew info thing').and_return output
    end

    context 'is not installed' do
      let(:output) do
        <<-OUTPUT
yaz: stable 4.2.56
http://www.indexdata.com/yaz
Depends on: pkg-config
Not installed
https://github.com/mxcl/homebrew/commits/master/Library/Formula/yaz.rb
        OUTPUT
      end

      specify { subject.should_not be_installed }
    end

    context 'is installed' do
      let(:output) do
        <<-OUTPUT
gdbm: stable 1.10
http://www.gnu.org/software/gdbm/
/usr/local/Cellar/gdbm/1.10 (10 files, 228K) *
https://github.com/mxcl/homebrew/commits/master/Library/Formula/gdbm.rb
==> Options
--universal
	Build a universal binary
        OUTPUT
      end

      specify { subject.should be_installed }
    end
  end
end
