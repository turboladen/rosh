class Rosh
  module FunctionalExampleGroup
    def self.included(base)
      base.metadata[:type] = :functional
    end
  end
end

shared_context 'hosts', type: :functional do
  before(:all) do
    Rosh.reset

    Rosh.add_host('192.168.33.100', host_label: :centos_57_64, user: 'vagrant',
      keys: [Dir.home + '/.vagrant.d/insecure_private_key'])
    Rosh.add_host('192.168.33.102', host_label: :debian_squeeze_32, user: 'vagrant',
      keys: [Dir.home + '/.vagrant.d/insecure_private_key'])
  end
end
