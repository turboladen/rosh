require 'spec_helper'
require 'rosh/host/package_managers/brew'


describe Rosh::Host::PackageManagers::Brew do
  let(:shell) { double 'Rosh::Host::Shell' }

  let(:observer) do
    o = double 'Observer'
    o.define_singleton_method(:update) do |one, two|
      #
    end

    o
  end

  before { subject.instance_variable_set(:@shell, shell) }

  subject do
    o = Object.new
    o.extend Rosh::Host::PackageManagers::Brew

    o
  end

  describe '#cache' do
    context 'cache is dirty' do
      let(:cache_dump) do
        <<-DUMP
Formula                                         hub-1.10.4.tgz
apple-gcc42-4.2.1-5666.3.pkg                    hub-1.10.5.tgz
atk-2.6.0.tar.xz                                iftop-1.0pre2.tar.gz
automake-1.12.2.tar.gz                          imagemagick-6.8.0-10.mountainlion.bottle.tar.gz
        DUMP
      end

      before do
        subject.instance_variable_set(:@cache, 'stuff')
        subject.instance_variable_set(:@cache_is_dirty, true)

        shell.should_receive(:exec).with('ls `brew --cache`').
          and_return cache_dump
      end

      it 'returns an Hash of cached packages' do
        cache = subject.cache

        cache.should == {
          'apple-gcc42' => { arch: '', version: '4.2.1-5666.3' },
          'atk'         => { arch: '', version: '2.6.0' },
          'automake'    => { arch: '', version: '1.12.2' },
          'hub'         => { arch: '', version: '1.10.4' },
          'hub'         => { arch: '', version: '1.10.5' },
          'iftop'       => { arch: '', version: '1.0pre2' },
          'imagemagick' => { arch: '', version: '6.8.0-10' },
        }
      end
    end

    context 'cache is not dirty' do
      before do
        subject.instance_variable_set(:@cache, cache)
        subject.instance_variable_set(:@cache_is_dirty, false)
      end

      let(:cache) { { 'package' => { arch: nil, version: nil } } }
      specify { subject.cache.should eq cache }
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
      shell.should_receive(:exec).with('brew list').and_return output
    end

    it 'creates a Brew package object for each package' do
      subject.should_receive(:create).with('apple-gcc42')
      subject.should_receive(:create).with('ffmpeg')
      subject.should_receive(:create).with('imagemagick')
      subject.should_receive(:create).with('atk')
      subject.should_receive(:create).with('freetype')
      subject.should_receive(:create).with('intltool')

      subject.installed_packages
    end
  end

  describe '#update_index' do
    before do
      shell.should_receive(:exec).with('brew update').and_return output
    end

    context 'cache does not change during update' do
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

    context 'cache changes after update' do
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
            with(subject, attribute: :index, old: [], new: updated)

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
    let(:output) { 'some output' }

    before do
      subject.stub(:installed_packages).and_return []
      shell.should_receive(:exec).with('brew upgrade').and_return output
    end

    context 'no packages to upgrade' do
      before do
        subject.should_receive(:extract_upgradable_packages).and_return []
      end

      context 'successful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 0
        end

        it 'returns true but does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == true
        end
      end

      context 'unsuccessful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 1
        end

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == false
        end
      end
    end

    context 'packages to upgrade' do
      before do
        subject.should_receive(:extract_upgradable_packages).
          and_return %w[upgrade_me]
      end

      context 'successful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 0
        end

        let(:brew_package) { double 'Rosh::Host::PackageTypes::Brew' }

        it 'returns true and notifies observers' do
          subject.should_receive(:create).and_return brew_package
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :installed_packages, old: [],
            new: [brew_package])

          subject.upgrade_packages.should == true
        end
      end

      context 'unsuccessful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 1
        end

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == false
        end
      end
    end
  end

  describe '#extract_upgradable_packages' do
    let(:output) do
      <<-EOF
      ==> Upgrading 17 outdated packages, with result:
atk 2.8.0, gmp 5.1.1, gtk+ 2.24.17, hub 1.10.6
      EOF
    end

    it 'returns an array of new Brew packages' do
      result = subject.send(:extract_upgradable_packages, output)
      result.should  eq %w[atk gmp gtk+ hub]
    end
  end
end
