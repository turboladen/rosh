require 'spec_helper'
require 'rosh/host/package_managers/brew'


describe Rosh::Host::PackageManagers::Brew do
  let(:shell) { double 'Rosh::Host::Shell' }
  before { allow(subject).to receive(:current_shell) { shell } }

  subject { Object.new.extend(Rosh::Host::PackageManagers::Brew) }

  describe '#bin_path' do
    context 'default' do
      specify { expect(subject.bin_path).to eq '/usr/local/bin' }
    end
  end

  describe '#installed_packages' do
    let(:output) do
      <<-OUTPUT
apple-gcc42			ffmpeg				imagemagick
atk				freetype			intltool
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('/usr/local/bin/brew list').and_return output
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

  describe '#update_definitions_command' do
    context 'default path' do
      specify do
        expect(subject.update_definitions_command).
          to eq '/usr/local/bin/brew update'
      end
    end
  end

  describe '#extract_update_definitions' do
    context 'output is an Exception' do
      it 'returns an empty Array' do
        output = RuntimeError.new
        expect(subject.send(:extract_updated_definitions, output)).to eq []
      end
    end

    context 'index does not change during update' do
      let(:output) do
        <<-OUTPUT
Already up-to-date.
        OUTPUT
      end

      it 'returns an empty Array' do
        expect(subject.send(:extract_updated_definitions, output)).to eq []
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

      it 'returns an Array of Hashes containing the updated package defs' do
        expect(subject.send(:extract_updated_definitions, output)).to eq updated
      end
    end
  end

  describe '#upgrade_packages_command' do
    specify do
      expect(subject.upgrade_packages_command).
        to eq '/usr/local/bin/brew upgrade'
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
