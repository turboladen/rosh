require 'spec_helper'
require 'rosh/host/package_managers/brew'


describe Rosh::Host::PackageManagers::Brew do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }

  let(:observer) do
    o = double 'Observer'
    o.define_singleton_method(:update) do |one, two|
      #
    end

    o
  end

  subject { Rosh::Host::PackageManagers::Brew.new(shell) }
  before { subject.instance_variable_set(:@shell, shell) }

  describe '#installed_packages' do
    let(:output) do
      <<-OUTPUT
apple-gcc42			ffmpeg				imagemagick
atk				freetype			intltool
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('brew list').and_return output
    end

    it 'creates a Brew package object for each package' do
      subject.should_receive(:create_package).with('apple-gcc42')
      subject.should_receive(:create_package).with('ffmpeg')
      subject.should_receive(:create_package).with('imagemagick')
      subject.should_receive(:create_package).with('atk')
      subject.should_receive(:create_package).with('freetype')
      subject.should_receive(:create_package).with('intltool')

      subject.installed_packages
    end
  end

  describe '#update_index' do
    before do
      shell.should_receive(:exec).with('brew update').and_return output
    end

    context 'index does not change during update' do
      let(:output) do
        <<-OUTPUT
Already up-to-date.
        OUTPUT
      end

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }

        it 'returns true and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_index.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_index.should == false
        end
      end
    end

    context 'index changes after update' do
      let(:output) do
        <<-OUTPUT
        Updated Homebrew from 6352f739 to 10bb62cb.
==> New Formulae
bpm-tools	   caudec		 homebrew/dupes/ed  timidity	       ydict
==> Updated Formulae
ack		      check		    elasticsearch
android-ndk	      checkstyle	    emacs
==> Deleted Formulae
wp-cli
        OUTPUT
      end

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }
        let(:updated) do
          [
            {
              new_formulae:
                %w[bpm-tools caudec homebrew/dupes/ed timidity ydict]
            }, {
            updated_formulae:
              %w[ack check elasticsearch android-ndk checkstyle emacs]
          }, {
            deleted_formulae:
              %w[wp-cli]
          }
          ]
        end

        it 'returns true and notifies observers' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :index, old: [], new: updated,
            as_sudo: false)

          subject.update_index.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_index.should == false
        end
      end
    end
  end

  describe '#upgrade_packages' do
    it 'runs `brew upgrade`' do
      shell.should_receive(:exec).with('brew upgrade')
      subject.upgrade_packages
    end
  end

  describe '#extract_upgraded_packages' do
    let(:output) do
      <<-EOF
      ==> Upgrading 17 outdated packages, with result:
atk 2.8.0, gmp 5.1.1, gtk+ 2.24.17, hub 1.10.6
      EOF
    end

    it 'returns an array of new Brew packages' do
      result = subject.send(:extract_upgraded_packages, output)
      result.should  eq %w[atk gmp gtk+ hub]
    end
  end
end
