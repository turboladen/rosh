# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant::Config.run do |config|
  provision = proc do |screenplay|

  end

  config.vm.define :centos_55_64 do |os|
    os.vm.host_name = 'centos-55-64'
    os.vm.box = 'centos-55-64'
    os.vm.box_url = 'http://dl.dropbox.com/u/15307300/vagrant-0.7-centos-64-base.box'
    os.vm.network :hostonly, '192.168.33.100'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :centos_62_32 do |os|
    os.vm.host_name = 'centos-62-32'
    os.vm.box = 'centos-62-32'
    os.vm.box_url = 'https://dl.dropbox.com/sh/9rldlpj3cmdtntc/56JW-DSK35/centos-62-32bit-puppet.box'
    os.vm.network :hostonly, '192.168.33.101'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :debian_squeeze_32 do |os|
    os.vm.host_name = 'debian-squeeze-32'
    os.vm.box = 'debian-squeeze-32'
    os.vm.box_url = 'https://dl.dropbox.com/u/2289657/squeeze32-vanilla.box'
    os.vm.network :hostonly, '192.168.33.102'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :freebsd_91_64 do |os|
    os.vm.host_name = 'freebsd-91-64'
    os.vm.box = 'freebsd-91-64'
    os.vm.box_url = 'https://s3.amazonaws.com/VagrantBoxen/freebsd_amd64_ufs.box'
    os.vm.network :hostonly, '192.168.33.104'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :gentoo_64 do |os|
    os.vm.host_name = 'gentoo-64'
    os.vm.box = 'gentoo-64'
    os.vm.box_url = 'http://dl.gusteau.gs/vagrant/gentoo64.box'
    os.vm.network :hostonly, '192.168.33.105'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :heroku_cedar do |os|
    os.vm.host_name = 'heroku_cedar'
    os.vm.box = 'heroku_cedar'
    os.vm.box_url = 'http://dl.dropbox.com/u/1906634/heroku.box'
    os.vm.network :hostonly, '192.168.33.106'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :openbsd_50_64 do |os|
    os.vm.host_name = 'openbsd-50-64'
    os.vm.box = 'openbsd-50-64'
    os.vm.box_url = 'https://github.com/downloads/stefancocora/openbsd_amd64-vagrant/openbsd50_amd64.box'
    os.vm.network :hostonly, '192.168.33.107'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :scientific_6_64 do |os|
    os.vm.host_name = 'scientific-6-64'
    os.vm.box = 'scientific-6-64'
    os.vm.box_url = 'http://lyte.id.au/vagrant/sl6-64-lyte.box'
    os.vm.network :hostonly, '192.168.33.108'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :ubuntu_1004_32 do |os|
    os.vm.host_name = 'ubuntu-1004-32'
    os.vm.box = 'lucid32'
    os.vm.box_url = 'http://files.vagrantup.com/lucid32.box'
    os.vm.network :hostonly, '192.168.33.109'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :ubuntu_1204_64 do |os|
    os.vm.host_name = 'ubuntu-1204-64'
    os.vm.box = 'precise64'
    os.vm.box_url = 'http://files.vagrantup.com/precise64.box'
    os.vm.network :hostonly, '192.168.33.110'
    # config.vm.provision :screenplay, &provision
  end

  config.vm.define :win2008 do |os|
    os.vm.boot_mode = :gui
    os.vm.guest = :windows
    os.vm.box = 'win2008'
    os.vm.box_url = 'http://dl.dropbox.com/u/58604/vagrant/win2k8r2-core.box'
    os.vm.network :hostonly, '192.168.33.10'
    os.vm.forward_port 3389, 3390, name: 'rdp', auto: true
    os.vm.forward_port 5985, 5985, name: 'winrm', auto: true
    os.winrm.timeout = 1800
    # config.vm.provision :screenplay, &provision
  end
end
