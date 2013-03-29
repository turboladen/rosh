require_relative 'file_system_object'


class Rosh
  class Host
    class FileSystem
      attr_reader :ssh_hostname
      attr_reader :last_command_result

      def initialize(ssh_hostname)
        @ssh_hostname = ssh_hostname
        @ssh = Rosh::Environment.hosts[@ssh_hostname].ssh
        @last_command_result = nil
      end

      def [](fs_object)
        FileSystemObject.new(fs_object, @ssh) do |last_command_result|
          @last_command_result = last_command_result
        end
      end
    end
  end
end
