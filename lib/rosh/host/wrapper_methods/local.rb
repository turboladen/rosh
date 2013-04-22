require 'sys/proctable'
require 'log_switch'


class Rosh
  class Host
    module WrapperMethods
      module Local
        extend LogSwitch
        include LogSwitch::Mixin

        # @param [String] path Path to the directory to list its contents.  If no
        #   path given, lists the current working directory.
        #
        # @return [Array<Rosh::LocalFileSystemObject>] On success, returns an
        #   Array of Rosh::LocalFileSystemObjects.  On fail, #last_exit_status is
        #   1 and returns a Errno::ENOENT or Errno::ENOTDIR.
        def ls(path=nil)
          log "ls called with arg '#{path}'"
          full_path = preprocess_path(path)

          process(:ls, path: path) do
            if File.file? full_path
              fso = Rosh::Host::LocalFileSystemObject.create(full_path)
              [fso, 0]
            else
              begin
                fso_array = Dir.entries(full_path).map do |entry|
                  good_info entry
                  Rosh::Host::LocalFileSystemObject.create("#{full_path}/#{entry}")
                end

                [fso_array, 0]
              rescue Errno::ENOENT, Errno::ENOTDIR => ex
                [ex, 1]
              end
            end
          end
        end

        # @param [String] name The name of a command to filter on.
        # @param [Integer] pid The pid of a command to find.
        #
        # @return [Array<Struct::ProcTableStruct>, Struct::ProcTableStruct] When
        #   no options are given, all processes returned.  When +:name+ is given,
        #   an Array of processes that match COMMAND are given.  When +:pid+ is
        #   given, a single process is returned.  See https://github.com/djberg96/sys-proctable
        #   for more info.
        def ps(name: nil, pid: nil)
          log "ps called with args 'name: #{name}', 'pid: #{pid}'"

          process(:ps, name: name, pid: pid) do
            ps = Sys::ProcTable.ps

            if name
              processes = ps.find_all { |i| i.cmdline =~ /\b#{name}\b/ }
              processes.each(&method(:ap))

              [processes, 0]
            elsif pid
              processes = ps.find { |i| i.pid == pid }
              processes.each(&method(:ap))

              [processes, 0]
            else
              ap ps

              [ps, 0]
            end
          end
        end
      end
    end
  end
end
