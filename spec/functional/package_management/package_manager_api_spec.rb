# require 'spec_helper'
# require 'rosh/package_manager/manager_adapters/apt'
# require 'rosh/package_manager/manager_adapters/brew'
# require 'rosh/package_manager/manager_adapters/yum'
#
#
# describe 'Package manager API' do
#   shared_examples_for 'a package manager' do
#     PUBLIC_INSTANCE_METHODS =
#       %i[
#         bin_path create_package installed_packages
#         update_definitions upgrade_packages
#       ]
#
#     PRIVATE_INSTANCE_METHODS =
#       %i[extract_updated_definitions extract_upgraded_packages]
#
#     OBSERVABLE_METHODS =
#       %i[add_observer changed notify_observers]
#
#     PUBLIC_INSTANCE_METHODS.each do |meth|
#       it "responds to instance method ##{meth.to_s}" do
#         expect(subject).to respond_to meth
#       end
#     end
#
#     PRIVATE_INSTANCE_METHODS.each do |meth|
#       it "responds to private instance method ##{meth.to_s}" do
#         subject.respond_to?(meth, true).should be_true
#       end
#     end
#
#     OBSERVABLE_METHODS.each do |meth|
#       it "responds to observable method ##{meth.to_s}" do
#         expect(subject).to respond_to meth
#       end
#     end
#   end
#
#   %i[apt dpkg brew yum].each do |package_manager|
#     describe package_manager do
#       subject { Rosh::PackageManager.new('example.com', package_manager) }
#       it_behaves_like 'a package manager'
#     end
#   end
# end
