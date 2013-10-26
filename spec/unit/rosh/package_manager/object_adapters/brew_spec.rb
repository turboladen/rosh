require 'spec_helper'
require 'rosh/package_manager/object_adapters/brew'


describe Rosh::PackageManager::ObjectAdapters::Brew do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }
  subject { Object.new.extend described_class }

  before do
    allow(subject).to receive(:current_shell) { shell }
    subject.instance_variable_set(:@name, 'thing')
    subject.instance_variable_set(:@bin_path, subject.send(:default_bin_path))
  end

  describe '#info' do
    before do
      expect(shell).to receive(:exec).with('/usr/local/bin/brew info thing') { output }
    end

    context 'installed' do
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

      it 'parses each field and value to a Hash' do
        expect(subject.info).to eq({
          package: 'thing',
          spec: 'stable',
          version: '2.0.21, HEAD',
          status: :installed,
          homepage: 'http://www.monkey.org/~provos/libevent/'
        })
      end
    end

    context 'not installed' do
      let(:output) do
        <<-OUTPUT
thing: stable 2.0.21, HEAD
http://www.monkey.org/~provos/libevent/
Not installed
https://github.com/mxcl/homebrew/commits/master/Library/Formula/libevent.rb
==> Options
--enable-manpages
	Install the libevent manpages (requires doxygen)
--universal
	Build a universal binary
        OUTPUT
      end

      it 'parses each field and value to a Hash' do
        expect(subject.info).to eq({
          package: 'thing',
          spec: 'stable',
          version: '2.0.21, HEAD',
          status: :not_installed,
          homepage: 'http://www.monkey.org/~provos/libevent/'
        })
      end
    end
  end

  describe '#installed?' do
    context 'not a package' do
      before do
        allow(shell).to receive(:last_exit_status) { 1 }
        expect(shell).to receive(:exec).with('/usr/local/bin/brew info thing') {
          'Error: No available formula for thing'
        }
      end

      specify { expect(subject).to_not be_installed }
    end

    context 'not installed' do
      before do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).with('/usr/local/bin/brew info thing') {
          %[garmintools: stable 0.10
http://code.google.com/p/garmintools/
Not installed
From: https://github.com/mxcl/homebrew/commits/master/Library/Formula/garmintools.rb
==> Dependencies
Required: libusb-compat]
        }
      end

      specify { expect(subject).to_not be_installed }
    end

    context 'installed' do
      before do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).with('/usr/local/bin/brew info thing') {
          %[git: stable 1.8.3.4, HEAD
http://git-scm.com
/usr/local/Cellar/git/1.8.3.1 (1324 files, 28M)
  Built from source
/usr/local/Cellar/git/1.8.3.3 (1326 files, 29M)
  Built from source
From: https://github.com/mxcl/homebrew/commits/master/Library/Formula/git.rb
==> Dependencies
Optional: pcre, gettext
==> Options
--with-blk-sha1
	Compile with the block-optimized SHA1 implementation
--with-gettext
	Build with gettext support
--with-pcre
	Build with pcre support
--without-completions
	Disable bash/zsh completions from "contrib" directory
==> Caveats
The OS X keychain credential helper has been installed to:
  /usr/local/bin/git-credential-osxkeychain

The 'contrib' directory has been installed to:
  /usr/local/share/git-core/contrib]
        }
      end

      specify { expect(subject).to be_installed }
    end
  end

  describe '#at_latest_version?' do
    context 'true' do
      before do
        allow(subject).to receive(:info) { { version: '1' } }
        allow(subject).to receive(:current_version) { '1' }
      end

      it 'returns true' do
        subject.should be_at_latest_version
      end
    end

    context 'false' do
      before do
        allow(subject).to receive(:info) { { version: '1' } }
        allow(subject).to receive(:current_version) { '2' }
      end

      it 'returns true' do
        subject.should_not be_at_latest_version
      end
    end
  end

  describe '#current_version' do
    context 'not installed' do
      before do
        allow(subject).to receive(:installed_versions) { [] }
      end

      it 'returns nil' do
        expect(subject.current_version).to be_nil
      end
    end

    context 'installed' do
      before do
        allow(subject).to receive(:installed_versions) { %w[1] }
      end

      it 'returns the currently installed version' do
        expect(subject.current_version).to eq '1'
      end
    end
  end

  describe '#installed_versions' do
    before do
      subject.instance_variable_set(:@name, 'git')
      expect(shell).to receive(:exec).with('/usr/local/bin/brew info git') { output }
    end

    context 'package not installed' do
      let(:output) do
        <<-OUTPUT
isl: stable 0.11.2, HEAD
http://www.kotnet.org/~skimo/isl/
Not installed
From: https://github.com/mxcl/homebrew/commits/master/Library/Formula/isl.rb
==> Dependencies
Required: gmp
        OUTPUT
      end

      specify { expect(subject.installed_versions).to eq [] }
    end

    context 'package installed' do
      let(:output) do
        <<-OUTPUT
git: stable 1.8.3.4, HEAD
http://git-scm.com
/usr/local/Cellar/git/1.8.3.1 (1324 files, 28M)
  Built from source
/usr/local/Cellar/git/1.8.3.3 (1326 files, 29M)
  Built from source
From: https://github.com/mxcl/homebrew/commits/master/Library/Formula/git.rb
        OUTPUT
      end

      specify { expect(subject.installed_versions).to eq %w[1.8.3.1 1.8.3.3] }
    end
  end

  describe '#default_bin_path' do
    specify { expect(subject.send(:default_bin_path)).to eq '/usr/local/bin' }
  end

  describe '#install_package' do
    context 'with version' do
      it 'calls #install_and_switch_version' do
        expect(subject).to receive(:install_and_switch_version).with('0.1.2')

        subject.send(:install_package, '0.1.2')
      end
    end

    context 'no version' do
      context 'failed install' do
        before do
          allow(shell).to receive(:last_exit_status) { 1 }
          expect(shell).to receive(:exec).with('/usr/local/bin/brew install thing')
        end

        specify { expect(subject.send(:install_package)).to eq false }
      end

      context 'successful install' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          expect(shell).to receive(:exec).with('/usr/local/bin/brew install thing')
        end

        specify { expect(subject.send(:install_package)).to eq true }
      end
    end
  end

  describe '#upgrade_package' do
    before do
      expect(shell).to receive(:exec).with('/usr/local/bin/brew upgrade thing')
    end

    context 'failed upgrade' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject.send(:upgrade_package)).to eq false }
    end

    context 'successful upgrade' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject.send(:upgrade_package)).to eq true }
    end
  end

  describe '#remove_package' do
    before do
      expect(shell).to receive(:exec).with('/usr/local/bin/brew remove thing')
    end

    context 'failed removal' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject.send(:remove_package)).to eq false }
    end

    context 'successful removal' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject.send(:remove_package)).to eq true }
    end
  end

  describe '#install_and_switch_version' do
    let(:version_output) do
      <<-OUTPUT
4.2.56   git checkout 9490f3b /usr/local/Library/Formula/thing.rb
1.2.3    git checkout 1234567 /usr/local/Library/Formula/thing.rb
      OUTPUT
    end

    context 'version does not exist' do
      it 'returns false' do
        expect(shell).to receive(:exec).
          with('/usr/local/bin/brew versions thing | grep asdf') { '' }

        expect(subject.send(:install_and_switch_version, 'asdf')).to eq false
      end
    end

    context 'version exists' do
      it 'passes the version to the command' do
        expect(shell).to receive(:exec).with('/usr/local/bin/brew versions thing | grep 1.2.3').
          and_return version_output
        expect(shell).to receive(:exec ).with('/usr/local/bin/brew --prefix') { '/usr/local' }
        expect(shell).to receive(:cd).with('/usr/local')

        expect(shell).to receive(:exec).with('git checkout 1234567 Library/Formula/thing.rb')
        expect(shell).to receive(:last_exit_status).and_return 0
        expect(shell).to receive(:exec).with('/usr/local/bin/brew unlink thing')
        expect(shell).to receive(:last_exit_status).and_return 0
        expect(shell).to receive(:exec).with('/usr/local/bin/brew install thing')
        expect(shell).to receive(:last_exit_status).and_return 0
        expect(shell).to receive(:exec).with('/usr/local/bin/brew switch thing 1.2.3')
        expect(shell).to receive(:last_exit_status).and_return 0
        expect(shell).to receive(:exec).with('git checkout -- Library/Formula/thing.rb')
        expect(shell).to receive(:last_exit_status).and_return 0

        expect(subject.send(:install_and_switch_version, '1.2.3')).to eq true
      end
    end
  end
end
