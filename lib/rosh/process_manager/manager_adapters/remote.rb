require_relative 'base'
require_relative '../remote_proc_table'


class Rosh
  class ProcessManager
    module ManagerAdapters
      class Remote
        include Base

        class << self

          # Runs `ps auxe` on the remote host and converts each line of process info
          # to a Rosh::ProcessManager::RemoteProcTable.
          #
          # @param [String] name The name of a command to filter on.
          # @param [Integer] pid The pid of a command to find.
          #
          # @return [Array<Rosh::ProcessManager::RemoteProcTable>, Rosh::ProcessManager::RemoteProcTable] When :name
          #   or no options are given, returns an Array of Rosh::ProcessManager::RemoteProcTable
          #   objects; when :pid is given, a single Rosh::ProcessManager::RemoteProcTable is returned.
          def list_running(name=nil, pid=nil)
            result = if pid
              current_shell.exec "ps uxe -p #{pid}"
            else
              current_shell.exec 'ps auxe'
            end

            list = []

            result.each_line do |line|
              match_data = %r[(?<user>\S+)\s+(?<pid>\S+)\s+(?<cpu>\S+)\s+(?<mem>\S+)\s+(?<vsz>\S+)\s+(?<rss>\S+)\s+(?<tty>\S+)\s+(?<stat>\S+)\s+(?<start>\S+)\s+(?<time>\S+)\s+(?<cmd>[^\n]+)].match(line)

              next if match_data[:user] == 'USER'
              list << Rosh::ProcessManager::RemoteProcTable.new(
                match_data[:user],
                match_data[:pid].to_i,
                match_data[:cpu].to_f,
                match_data[:mem].to_f,
                match_data[:vsz].to_i,
                match_data[:rss].to_i,
                match_data[:tty],
                match_data[:stat],
                Time.parse(match_data[:start]),
                match_data[:time],
                match_data[:cmd].strip
              )
            end

            filtered_list = if name
              list.find_all { |i| i.command =~ /\b#{name}\b/ }
            elsif pid
              list.find_all { |i| i.pid == pid }
            else
              list
            end

            filtered_list.map do |process_struct|
              process = Rosh::ProcessManager::Process.new(process_struct.pid, @host_name)
              process.struct = process_struct

              process
            end
          end
        end
      end
    end
  end
end
