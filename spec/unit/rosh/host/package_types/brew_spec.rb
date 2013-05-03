require 'spec_helper'
require 'rosh/host/package_types/brew'


describe Rosh::Host::PackageTypes::Brew do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }

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

  describe '#install' do
    context 'with version' do
      before do
        subject.should_receive(:installed?).and_return true
        subject.stub_chain(:info, :[]).and_return '0.1.2'
      end

      it 'calls #install_and_switch_version' do
        subject.should_receive(:install_and_switch_version).with '1.2.3'

        subject.install version: '1.2.3'
      end
    end

    context 'no version' do
      before do
        shell.should_receive(:exec).with('brew install thing')
      end

      context 'package was already installed and at latest version' do
        before do
          subject.stub_chain(:info, :[]).and_return '1.2.3'
          subject.should_receive(:installed?).and_return true
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before { shell.stub(:last_exit_status).and_return 0 }
          specify { subject.install.should == true }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end
      end

      context 'package was already installed but at older version' do
        before do
          subject.should_receive(:installed?).and_return true
          subject.stub_chain(:info, :[]).and_return '0.1.2', '1.2.3'
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before { shell.stub(:last_exit_status).and_return 0 }
          specify { subject.install.should == true }

          it 'notifies observers' do
            subject.should_receive(:changed)
            subject.should_receive(:notify_observers).
              with(subject, attribute: :version, old: '0.1.2', new: '1.2.3',
              as_sudo: false)

            subject.install
          end
        end
      end

      context 'package not yet installed' do
        before do
          subject.should_receive(:installed?).and_return false
          subject.stub_chain(:info, :[]).and_return '1.2.3'
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before do
            shell.stub(:last_exit_status).and_return 0
            subject.stub_chain(:info, :[]).and_return '1.2.3'
          end

          specify { subject.install.should == true }

          it 'notifies observers' do
            subject.should_receive(:changed)
            subject.should_receive(:notify_observers).
              with(subject, attribute: :version, old: nil, new: '1.2.3',
              as_sudo: false)

            subject.install
          end
        end
      end
    end
  end

  describe '#remove' do
    before do
      shell.should_receive(:exec).with('brew remove thing')
      subject.stub_chain(:info, :[]).and_return '1.2.3'
    end

    context 'package was already installed' do
      before do
        subject.should_receive(:installed?).and_return true
      end

      context 'failed removal' do
        before { shell.stub(:last_exit_status).and_return 1 }
        specify { subject.remove.should == false }

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end

      context 'successful removal' do
        before { shell.stub(:last_exit_status).and_return 0 }
        specify { subject.remove.should == true }

        it 'notifies observers' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :version, old: '1.2.3', new: nil,
            as_sudo: false)

          subject.remove
        end
      end
    end

    context 'package not yet installed' do
      before do
        subject.should_receive(:installed?).and_return false
      end

      context 'failed removal' do
        before { shell.stub(:last_exit_status).and_return 1 }
        specify { subject.remove.should == false }

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end

      context 'successful removal' do
        before do
          shell.stub(:last_exit_status).and_return 0
          subject.stub_chain(:info, :[]).and_return '1.2.3'
        end

        specify { subject.remove.should == true}

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end
    end
  end

  describe '#upgrade' do
    before do
      subject.stub_chain(:info, :[]).and_return '1.2.3'
      shell.should_receive(:exec).with('brew upgrade thing')
    end

    context 'package not already installed' do
      before { shell.should_receive(:last_exit_status).and_return 1 }

      it 'returns false and does not update observers' do
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.upgrade.should == false
      end
    end

    context 'package installed but latest' do
      before { shell.should_receive(:last_exit_status).and_return 1 }

      it 'returns false and does not update observers' do
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.upgrade.should == false
      end
    end

    context 'package installed and outdated' do
      before do
        shell.should_receive(:last_exit_status).and_return 0
        subject.stub_chain(:info, :[]).and_return '0.1.2', '1.2.3'
      end

      it 'returns true and updates observers' do
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :version, old: '0.1.2', new: '1.2.3',
          as_sudo: false)

        subject.upgrade.should == true
      end
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
        shell.should_receive(:exec).with('brew versions thing | grep asdf').
          and_return ''

        subject.send(:install_and_switch_version, 'asdf').should == false
      end
    end

    context 'version exists' do
      it 'passes the version to the command' do
        shell.should_receive(:exec).with('brew versions thing | grep 1.2.3').
          and_return version_output
        shell.should_receive(:exec ).with('brew --prefix').and_return '/usr/local'
        shell.should_receive(:cd).with('/usr/local')

        shell.should_receive(:exec).with('git checkout 1234567 Library/Formula/thing.rb')
        shell.should_receive(:last_exit_status).and_return 0
        shell.should_receive(:exec).with('brew unlink thing')
        shell.should_receive(:last_exit_status).and_return 0
        shell.should_receive(:exec).with('brew install thing')
        shell.should_receive(:last_exit_status).and_return 0
        shell.should_receive(:exec).with('brew switch thing 1.2.3')
        shell.should_receive(:last_exit_status).and_return 0
        shell.should_receive(:exec).with('git checkout -- Library/Formula/thing.rb')
        shell.should_receive(:last_exit_status).and_return 0

        subject.send(:install_and_switch_version, '1.2.3').should == true
      end
    end
  end
end
