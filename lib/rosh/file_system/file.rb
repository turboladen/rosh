require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'
require_relative '../command'
require_relative 'state_machine'


class Rosh
  class FileSystem

    # A Rosh::FileSystem::File can represent either a file on a local host or a
    # remote host.  It allows you to interact with a file on your file system
    # in an object-oriented manner.
    #
    # Additionally, Files are observable: they can notify other objects when
    # they change.  Observing objects must have an #update method defined that
    # takes parameter list: `(changed_file, attribute: nil, old: nil, new: nil,
    # as_sudo: nil)`.
    #
    #   class MyWatcher
    #     def update(changed_file, attribute: nil, old: nil, new: nil, as_sudo: nil)
    #       puts "File '#{changed_file.path}' changed:"
    #       puts "  attribute:  #{attribute}"
    #       puts "  old value:  #{old}"
    #       puts "  new value:  #{new}"
    #       puts "  using sudo? #{as_sudo}
    #     end
    #   end
    #
    #   watcher = MyWatcher.new
    #   file = Rosh::FileSystem::File.new('/tmp/my_file', 'my_host.com')
    #   file.add_observer(watcher)
    #   file.mode           # => 755
    #   file.chmod(644)
    #   # =>  "File '/tmp/my_file' changed:"
    #   #     "  attribute:  :mode"
    #   #     "  old value:  755"
    #   #     "  new value:  644"
    #   #     "  using sudo? false"
    #
    # The following File attributes can be observed:
    #   * :mode
    #   * :lmode
    #   * :owner
    #   * :lowner
    #   * :exists
    #   * :hard_link
    #   * :symbolic_link
    #   * :name
    #   * :size
    #   * :access_time
    #   * :modification_time
    #
    # Note that notifications/observations are only triggered when made through
    # Rosh--changes external to Rosh are not detected.
    #
    class File
      include BaseMethods
      include StatMethods
      include StateMachine

      def initialize(path, host_name)
        @path = path
        @host_name = host_name

        self.state = exists? ? :persisted : :transient
      end

      # @return [Rosh::Host]
      def host
        Rosh.find_by_host_name(@host_name)
      end

      def updated(*args)
        puts "YOOOOOOO UPdated: #{args}"
      end

      # @return [Rosh::Shell::PrivateCommandResult]
      def contents
        echo_rosh_command

        log "State: #{state}"

        command = if dirtied? || transient?
          Rosh::Command.new(method(__method__)) do
            adapter.unwritten_contents
          end
        else
          Rosh::Command.new(method(__method__), &adapter.method(:read).to_proc)
        end

        command.execute!
      end

      # Stores +new_contents+ in memory until #save is called.
      #
      # @param [String] new_contents Contents to write to the file on #save.
      # @return [Rosh::Shell::PrivateCommandResult]
      def contents=(new_contents)
        echo_rosh_command new_contents

        current_contents = self.contents

        command = Rosh::Command.new(method(__method__), new_contents) do
          adapter.unwritten_contents = new_contents
          adapter.save
        end

        command.change_if = -> { !new_contents == current_contents }
        command.did_change_succeed = -> { new_contents == current_contents }
        command.after_change = lambda do |result|
          update(:contents, result, host.shell.su?, from: current_contents, to: new_contents)
        end

        command.execute!
      end

      # Copies this File object to the +destination+.  If the copy was
      # successful and a block is given, yields the new File to the block; the
      # return value is the result of this command--not any internal commands.
      #
      # @param [String] destination
      # @return [Rosh::FileSystem::File] The newly copied filed.
      def copy_to(destination)
        echo_rosh_command destination

        the_copy = current_host.fs[file: destination]

        command = Rosh::Command.new(method(__method__), destination,
          &adapter.method(:copy).to_proc)
        command.change_if = proc do
          !the_copy.persisted? &&
            the_copy.size != self.size &&
            the_copy.contents != self.contents
        end

        command.did_change_succeed = proc do
          the_copy.persisted? &&
            the_copy.size == self.size &&
            the_copy.contents == self.contents
        end

        command.after_change = lambda do |result|
          update(:exists?, result, host.shell.su?, from: false, to: true)
        end

        command.execute!
      end

      # Hard links this File object to the +new_path+.  If the link creation was
      # successful and a block is given, yields the new File to the block; the
      # return value is the result of this command--not any internal commands.
      #
      # @param [String] new_path
      # @return [Rosh::Shell::PrivateCommandResult]
      def hard_link_to(new_path)
        echo_rosh_command new_path
        new_link = host.fs[file: new_path]

        command = Rosh::Command.new(method(__method__), new_path,
          &adapter.method(:link).to_proc)
        command.change_if = -> { !new_link.exists? }

        command.did_change_succeed = proc do
          new_link.exists? && new_link.persisted? &&
            new_link.contents == self.contents
        end

        command.after_change = lambda do
          update(:exists?, new_link, host.shell.su?, from: false, to: true)
        end

        command.execute!
      end
      alias_method :link, :hard_link_to

      # @param [Fixnum] length
      # @param [Fixnum] offset
      # @return [Rosh::Shell::PrivateCommandResult]
      def read(length=nil, offset=nil)
        echo_rosh_command length, offset

        Rosh._run_command(method(__method__), length, offset, &adapter.method(__method__).to_proc)
      end

      # @return [Array<String>]
      def readlines(separator=$/)
        echo_rosh_command separator

        Rosh._run_command(method(__method__), separator, &adapter.method(__method__).to_proc)
      end

      def each_line(separator=$/, &block)
        echo_rosh_command separator

        Rosh._run_command(method(__method__), separator) do
          contents.each_line(&block)
        end
      end

      def save
        echo_rosh_command

        previous_state = self.state
        log "Previous state: #{previous_state}"

        command = Rosh::Command.new(method(__method__), &adapter.method(:save).to_proc)
        command.change_if = -> { !self.persisted? }
        command.did_change_succeed = -> { self.persisted? }
        command.after_change = lambda do |result|
          if result.exit_status.zero?
            adapter.unwritten_contents.clear

            case previous_state
            when :transient
              persist(:exists?, result, host.shell.su?,
                from: false, to: true)
            when :dirtied
              persist(:dirtied?, result, host.shell.su?,
                from: true, to: false)
            end
          end
        end

        command.execute!
      end

      # Called by serializer when dumping.
      def encode_with(coder)
        coder['path'] = @path
        coder['host_name'] = @host_name
      end

      # Called by serializer when loading.
      def init_with(coder)
        @path = coder['path']
        @host_name = coder['host_name']
      end

      def adapter
        return @adapter if @adapter

        type = if host.local?
          :local_file
        else
          :remote_file
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
