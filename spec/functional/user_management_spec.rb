require 'spec_helper'
require 'rosh'


shared_examples_for 'a user manager' do
  it 'can list users' do
    list = host.users.list_users

    list.each do |user|
      expect(user).to be_a Rosh::UserManager::User
    end
  end

  it 'can list groups' do
    list = host.users.list_groups

    list.each do |group|
      expect(group).to be_a Rosh::UserManager::Group
    end
  end

  it 'can create and delete a user' do
    host.su do
      host.users[user: user].create
      expect(host.users[user].exists?).to eq true

      host.users[user].delete
      expect(host.users[user].exists?).to eq false
    end
  end

  it 'can create and delete a group' do
    host.su do
      host.users[group: user].create
      expect(host.users[user].exists?).to eq true

      host.users[group].delete
      expect(host.users[user].exists?).to eq false
    end
  end
end

describe 'User Management' do
  include_context 'hosts'
  let(:user) { 'bobo' }

  context 'centos' do
    it_behaves_like 'a user manager' do
      let(:host) { Rosh.hosts[:centos_57_64] }
    end
  end

  context 'debian' do
    it_behaves_like 'a user manager' do
      let(:host) { Rosh.hosts[:debian_squeeze_32] }
    end
  end
end
