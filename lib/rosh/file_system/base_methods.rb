require_relative '../command'
require_relative 'state_machine'


class Rosh
  class FileSystem
    module BaseMethods
      include Rosh::Command
      include Rosh::FileSystem::StateMachine

      # @param [String] dir_string
      def absolute_path(dir_string=nil)
        run_command { adapter.absolute_path(dir_string) }
      end

      def access_time
        run_command { adapter.atime }
      end
      alias_method :atime, :access_time

      def access_time=(new_time)
        echo_rosh_command new_time

        current_atime = self.access_time
        current_mtime = self.modification_time
        idempotency_check = -> { current_atime != new_time }

        run_command(idempotency_check) do
          cmd_result = adapter.utime(new_time, current_mtime)
          updated(:access_time, cmd_result, current_shell.su?, from: current_atime, to: new_time)

          cmd_result
        end
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def base_name(suffix=nil)
        run_command { adapter.basename(suffix) }
      end
      alias_method :basename, :base_name

      def change_mode_to(new_mode)
        echo_rosh_command new_mode

        current_mode = self.mode
        idempotency_check = -> { !current_mode.to_s.end_with?(new_mode.to_s) }

        run_command(idempotency_check) do
          cmd_result = adapter.chmod(new_mode)
          updated(:mode, cmd_result, current_shell.su?, from: current_mode, to: new_mode)

          cmd_result
        end
      end
      alias_method :mode=, :change_mode_to
      alias_method :chmod, :change_mode_to

      def change_time
        run_command { adapter.ctime }
      end
      alias_method :ctime, :change_time

=begin
      def create
        change_if(!exists?) do
          notify_about(self, :exists?, from: false, to: true) do
            adapter.create
          end
        end
      end
=end

      def delete
        echo_rosh_command

        run_command(-> { self.exists? }) do
          adapter.delete
        end
      end
      alias_method :unlink, :delete

      def directory_name
        run_command { adapter.dirname }
      end
      alias_method :dirname, :directory_name

      def expand_path(dir_string=nil)
        run_command { adapter.expand_path(dir_string) }
      end

      def extension
        run_command { adapter.extname }
      end
      alias_method :extname, :extension

      def file_name_match(pattern, *flags)
        run_command { adapter.fnmatch(pattern, *flags) }
      end
      alias_method :fnmatch, :file_name_match
      alias_method :fnmatch?, :file_name_match

      def file_type
        run_command { adapter.ftype }
      end
      alias_method :ftype, :file_type

      # @todo Return a Rosh Group object.
      def group
        warn 'Not implemented'
      end

      def group=(new_group)
        echo_rosh_command new_group

        current_group = self.gid
        new_group = new_group.to_i

        run_command(-> { new_group != current_group }) do
          cmd_result = adapter.chown(gid: new_group)
          update(:group, cmd_result, current_shell.su?, from: current_group, to: new_group)
          cmd_result
        end
      end

      def modification_time
        echo_rosh_command

        run_command { adapter.mtime }
      end
      alias_method :mtime, :modification_time

      def modification_time=(new_time)
        echo_rosh_command new_time

        current_atime = self.access_time
        current_mtime = self.modification_time

        run_command(-> { current_mtime != new_time }) do
          cmd_result = adapter.utime(current_atime, new_time)
          update(:modification_time, cmd_result, current_shell.su?, from: current_mtime, to: new_time)
          cmd_result
        end
      end

      # @todo Return a Rosh User object.
      def owner
        warn 'Not implemented'
      end

      def owner=(new_owner)
        echo_rosh_command new_owner

        current_owner = self.uid
        new_owner = new_owner.to_i

        run_command(-> { new_owner != current_owner }) do
          cmd_result = adapter.chown(uid: new_owner)
          update(:owner, cmd_result, current_shell.su?, from: current_owner, to: new_owner)
          cmd_result
        end
      end

      # Returns the pathname used to create file as a String. Does not normalize
      # the name.
      #
      # @return [String]
      def path
        run_command { adapter.path }
      end

      def read_link
        run_command { adapter.readlink }
      end
      alias_method :readlink, :read_link

      def real_dir_path(dir_path=nil)
        run_command { adapter.realdirpath(dir_path) }
      end
      alias_method :realdirpath, :real_dir_path

      def real_path(dir_path=nil)
        run_command { adapter.realpath(dir_path) }
      end
      alias_method :realpath, :real_path

      def rename_to(new_name)
        echo_rosh_command new_name

        new_object = current_host.fs[object: new_name]
        current_path = self.expand_path

        run_command(-> { !new_object.exists? }) do
          cmd_result = adapter.rename(new_name)
          update(:path, cmd_result, current_shell.su?, from: current_path, to: new_name)
        end
      end
      alias_method :name=, :rename_to
      alias_method :rename, :rename_to

      def size
        run_command { adapter.size }
      end

      def split
        run_command { adapter.split }
      end

      def stat
        run_command { adapter.stat }
      end

      def symbolic_link_from(new_path)
        echo_rosh_command new_path

        new_link = current_host.fs[link: new_path]

        run_command(-> { !new_link.exists? }) do
          adapter.symlink(new_path)
        end
      end
      alias_method :symlink, :symbolic_link_from

      def to_s
        path.to_s
      end

      def to_path
        adapter.to_path
      end

      def truncate(new_size)
        echo_rosh_command new_size

        current_size = self.size

        run_command(-> { new_size < current_size }) do
          cmd_result = adapter.truncate(new_size)
          update(:size, cmd_result, current_shell.su?, from: current_size, to: new_size)
          cmd_result
        end
      end

      def set_file_times(access_time, modification_time)
        echo_rosh_command access_time, modification_time

        self.access_time = access_time
        self.modification_time = modification_time
      end
      alias_method :utime, :set_file_times

      def lock(types)
        echo_rosh_command types

        run_command { adapter.flock(types) }
      end
      alias_method :flock, :lock
    end
  end
end
