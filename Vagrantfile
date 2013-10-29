# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.define :centos_57_64 do |os|
    os.vm.box = 'centos-57-64'
    os.vm.box_url = 'http://www.lyricalsoftware.com/downloads/centos-5.7-x86_64.box'
    os.vm.hostname = 'centos-57-64'
    os.vm.network :private_network, ip: '192.168.33.100'
  end

  config.vm.define :centos_62_32 do |os|
    os.vm.box = 'centos-62-32'
    os.vm.box_url = 'https://dl.dropbox.com/sh/9rldlpj3cmdtntc/56JW-DSK35/centos-62-32bit-puppet.box'
    os.vm.hostname = 'centos-62-32'
    os.vm.network :private_network, ip: '192.168.33.101'
  end

  config.vm.define :debian_squeeze_32 do |os|
    os.vm.box = 'debian-squeeze-32'
    os.vm.box_url = 'https://dl.dropbox.com/u/2289657/squeeze32-vanilla.box'
    os.vm.hostname = 'debian-squeeze-32'
    os.vm.network :private_network, ip: '192.168.33.102'
  end

  config.vm.define :debian_wheezy_64 do |os|
    os.vm.box = 'debian-wheezy-64'
    os.vm.box_url = 'https://dl.dropboxusercontent.com/u/197673519/debian-7.2.0.box'
    os.vm.hostname = 'debian-wheezy-64'
    os.vm.network :private_network, ip: '192.168.33.103'
  end

  # https://github.com/wunki/vagrant-freebsd
  config.vm.define :freebsd_92_64 do |os|
    os.vm.box = 'freebsd-92-64'
    os.vm.box_url = 'https://wunki.org/files/freebsd-9.2-amd64-wunki.box'
    os.vm.guest = :freebsd
    os.vm.hostname = 'freebsd-92-64'
    os.vm.network :private_network, ip: '192.168.33.104'
  end

  config.vm.define :gentoo_64 do |os|
    os.vm.box = 'gentoo-64'
    os.vm.box_url = 'http://dl.gusteau.gs/vagrant/gentoo64.box'
    os.vm.hostname = 'gentoo-64'
    os.vm.network :private_network, ip: '192.168.33.105'
  end

  config.vm.define :heroku_cedar do |os|
    os.vm.box = 'heroku_cedar'
    os.vm.box_url = 'http://dl.dropbox.com/u/1906634/heroku.box'
    os.vm.hostname = 'heroku-cedar'
    os.vm.network :private_network, ip: '192.168.33.106'
  end

  config.vm.define :openbsd_50_64 do |os|
    os.vm.box = 'openbsd-50-64'
    os.vm.box_url = 'https://github.com/downloads/stefancocora/openbsd_amd64-vagrant/openbsd50_amd64.box'
    os.vm.guest = :openbsd
    os.vm.hostname = 'openbsd-50-64'
    os.vm.network :private_network, ip: '192.168.33.107'
  end

  config.vm.define :scientific_6_64 do |os|
    os.vm.box = 'scientific-6-64'
    os.vm.box_url = 'http://lyte.id.au/vagrant/sl6-64-lyte.box'
    os.vm.hostname = 'scientific-6-64'
    os.vm.network :private_network, ip: '192.168.33.108'
  end

  config.vm.define :ubuntu_1004_32 do |os|
    os.vm.box = 'lucid32'
    os.vm.box_url = 'http://files.vagrantup.com/lucid32.box'
    os.vm.hostname = 'ubuntu-1004-32'
    os.vm.network :private_network, ip: '192.168.33.109'
  end

  config.vm.define :ubuntu_1204_64 do |os|
    os.vm.box = 'precise64'
    os.vm.box_url = 'http://files.vagrantup.com/precise64.box'
    os.vm.hostname = 'ubuntu-1204-64'
    os.vm.network :private_network, ip: '192.168.33.110'
  end

  config.vm.define :win2008 do |os|
    os.vm.boot_mode = :gui
    os.vm.guest = :windows
    os.vm.box = 'win2008'
    os.vm.box_url = 'http://dl.dropbox.com/u/58604/vagrant/win2k8r2-core.box'
    os.vm.network :private_network, ip: '192.168.33.10'
    os.vm.forward_port 3389, 3390, name: 'rdp', auto: true
    os.vm.forward_port 5985, 5985, name: 'winrm', auto: true
    os.winrm.timeout = 1800
  end
end
