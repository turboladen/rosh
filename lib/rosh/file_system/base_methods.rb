require_relative '../command'
require_relative 'state_machine'


class Rosh
  class FileSystem
    module BaseMethods
      include Rosh::FileSystem::StateMachine

      # @param [String] dir_string
      def absolute_path(dir_string=nil)
        Rosh::Command.new(method(__method__), dir_string,
          &adapter.method(__method__).to_proc).execute!
      end

      # @return [Time]
      def access_time
        Rosh._run_command(method(__method__), &adapter.method(:atime).to_proc)
      end
      alias_method :atime, :access_time

      # @param [Time] new_time
      def access_time=(new_time)
        echo_rosh_command new_time

        current_mtime = self.modification_time
        command = Rosh::Command.new(method(__method__), new_time) do
          adapter.utime(new_time, current_mtime)
        end

        command.change_if = -> { self.access_time != new_time }
        command.did_change_succeed = -> { self.access_time == new_time }

        command.after_change = proc do
          updated(:access_time, cmd_result, Rosh.environment.current_shell.su?, from: current_atime, to: new_time)
        end

        command.execute!
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def base_name(suffix=nil)
        Rosh._run_command(method(__method__), suffix, &adapter.method(:basename).to_proc)
      end
      alias_method :basename, :base_name

      def change_mode_to(new_mode)
        echo_rosh_command new_mode

        current_mode = self.mode

        command = Rosh::Command.new(method(__method__), new_mode, &adapter.method(:chmod).to_proc)
        # TODO: this check isn't correct
        command.change_if = -> { !current_mode.to_s.end_with?(new_mode.to_s) }
        command.did_change_succeed = -> { current_mode == self.mode }

        command.after_change = proc do |result|
          updated(:mode, result, Rosh.environment.current_shell.su?, from: current_mode, to: new_mode)
        end

        command.execute!
      end
      alias_method :mode=, :change_mode_to
      alias_method :chmod, :change_mode_to

      # @return [Time]
      def change_time
        Rosh._run_command(method(__method__), &adapter.method(:ctime).to_proc)
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

        command = Rosh::Command.new(method(__method__), &adapter.method(:delete).to_proc)
        command.change_if = -> { self.exists? }
        command.did_change_succeed = -> { !self.exists? }
        command.after_change = lambda do |result|
          updated(:exists?, result, Rosh.environment.current_shell.su?, from: true, to: false)
        end

        command.execute!
      end
      alias_method :unlink, :delete

      # @return [String]
      def directory_name
        Rosh._run_command(method(__method__), &adapter.method(:dirname).to_proc)
      end
      alias_method :dirname, :directory_name

      # @return [String]
      def expand_path(dir_string=nil)
        Rosh._run_command(method(__method__), dir_string, &adapter.method(:expand_path).to_proc)
      end

      # @return [String]
      def extension
        Rosh._run_command(method(__method__), &adapter.method(:extname).to_proc)
      end
      alias_method :extname, :extension

      def file_name_match(pattern, *flags)
        Rosh._run_command(method(__method__), pattern, *flags, &adapter.method(:fnmatch).to_proc)
      end
      alias_method :fnmatch, :file_name_match
      alias_method :fnmatch?, :file_name_match

      # @return [String]
      def file_type
        Rosh._run_command(method(__method__), &adapter.method(:ftype).to_proc)
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

        command = Rosh::Command.new(method(__method__), new_group) do
          adapter.chown(nil, new_group)
        end

        command.change_if = -> { new_group != current_group }
        # Commenting out until implementation of #group
        # command.did_change = -> { self.group == current_group }
        command.did_change_succeed = -> { true }
        command.after_change = lambda do |result|
          update(:group, result, host.shell.su?, from: current_group, to: new_group)
        end

        command.execute!
      end

      # @return [Time]
      def modification_time
        echo_rosh_command
        Rosh._run_command(method(__method__), &adapter.method(:mtime).to_proc)
      end
      alias_method :mtime, :modification_time

      # @param [Time] new_time
      def modification_time=(new_time)
        echo_rosh_command new_time
        old_mtime = self.modification_time

        command = Rosh::Command.new(method(__method__), new_time) do
          old_atime = self.access_time
          adapter.utime(old_atime, new_time)
        end

        command.change_if = -> { old_mtime != new_time }
        command.did_change_succeed = -> { self.modification_time == new_time }
        command.after_change = lambda do |result|
          update(:modification_time, result, host.shell.su?, from: old_mtime, to: new_time)
        end

        command.execute!
      end

      # @todo Return a Rosh User object.
      def owner
        warn 'Not implemented'
      end

      def owner=(new_owner)
        echo_rosh_command new_owner

        current_owner = self.uid
        new_owner = new_owner.to_i

        command = Rosh::Command.new(method(__method__), new_owner, &adapter.method(:chown).to_proc)
        command.change_if = -> { new_owner != current_owner }
        # Commenting out until implementation of #owner
        # command.did_change = -> { self.owner == new_owner }
        command.did_change_succeed = -> { true }
        command.after_change = lambda do |result|
          update(:owner, result, host.shell.su?, from: current_owner, to: new_owner)
        end

        command.execute!
      end

      # Returns the pathname used to create file as a String. Does not normalize
      # the name.
      #
      # @return [String]
      def path
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      def read_link
        Rosh._run_command(method(__method__), &adapter.method(:readlink).to_proc)
      end
      alias_method :readlink, :read_link

      # @param [String] dir_path
      # @return [String]
      def real_dir_path(dir_path=nil)
        Rosh._run_command(method(__method__), dir_path, &adapter.method(:realdirpath).to_proc)
      end
      alias_method :realdirpath, :real_dir_path

      # @param [String] dir_path
      # @return [String]
      def real_path(dir_path=nil)
        Rosh._run_command(method(__method__), dir_path, &adapter.method(:realpath).to_proc)
      end
      alias_method :realpath, :real_path

      # @param [String] new_name
      # @return [Boolean]
      def rename_to(new_name)
        echo_rosh_command new_name

        new_object = Rosh.environment.current_host.fs[object: new_name]
        current_path = self.expand_path

        command = Rosh::Command.new(method(__method__), new_name, &adapter.method(:rename).to_proc)
        command.change_if = -> { !new_object.exists? }
        command.did_change_succeed = proc do
          new_object.exists? && !File.exists?(current_path) &&
            FileUtils.compare_file(current_path, new_name)
        end

        command.after_change = lambda do |result|
          update(:path, result, host.shell.su?, from: current_path, to: new_name)
        end

        command.execute!
      end
      alias_method :name=, :rename_to
      alias_method :rename, :rename_to

      # @return [Fixnum]
      def size
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      # @return [String]
      def split
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      # TODO: This should probably return a Rosh-specific stat object (to account for remote hosts)
      # @return [File::Stat]
      def stat
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      # @param [String] new_path The symlink to create and link to this object.
      # @return [Boolean]
      def symbolic_link_from(new_path)
        echo_rosh_command new_path

        new_link = Rosh.environment.current_host.fs[symbolic_link: new_path]
        command = Rosh::Command.new(method(__method__), new_path, &adapter.method(:symlink).to_proc)
        command.change_if = -> { !new_link.exists? }
        command.did_change_succeed = proc do
          new_link.exists? && new_link.destination == self.path
        end

        command.after_change = proc do
          update(:symbolic_link_from, self, host.shell.su?, from: nil, to: new_path)
        end

        command.execute!
      end
      alias_method :symlink, :symbolic_link_from

      # @return [String]
      def to_path
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      # @param [Fixnum] new_size
      # @return [Boolean]
      def truncate(new_size)
        echo_rosh_command new_size

        current_size = self.size
        command = Rosh::Command.new(method(__method__), new_size, &adapter.method(:truncate).to_proc)
        command.change_if = -> { new_size < current_size }
        command.did_change_succeed = -> { self.size == new_size }
        command.after_change = lambda do |result|
          update(:size, result, host.shell.su?, from: current_size, to: new_size)
        end

        command.execute!
      end

      # @param [Time] new_access_time
      # @param [Time] new_modification_time
      def set_file_times(new_access_time, new_modification_time)
        echo_rosh_command new_access_time, new_modification_time

        old_access_time = self.access_time
        old_modification_time = self.modification_time

        command = Rosh::Command.new(method(__method__), new_access_time, new_modification_time,
          &adapter.method(:utime).to_proc)

        command.change_if = proc do
          old_access_time != new_access_time ||
            old_modification_time != new_modification_time
        end

        command.did_change_succeed = proc do
          self.access_time.to_i == new_access_time.to_i &&
            self.modification_time.to_i == new_modification_time.to_i
        end

        command.after_change = lambda do |result|
          update(:file_times, result, host.shell.su?,
            from: { access_time: old_access_time, modification_time: old_modification_time },
            to: { access_time: self.access_time, modification_time: self.modification_time })
        end

        command.execute!
      end
      alias_method :utime, :set_file_times

      # @param [Fixnum] types
      def lock(types)
        echo_rosh_command types

        Rosh._run_command(method(__method__), types, &adapter.method(:flock).to_proc)
      end
      alias_method :flock, :lock
    end
  end
end
