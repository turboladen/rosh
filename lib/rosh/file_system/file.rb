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

        self.state = exists?.ruby_object ? :persisted : :transient
      end

      # @return [Rosh::Shell::PrivateCommandResult]
      def contents
        echo_rosh_command

        run_command do
          if dirtied? || transient?
            private_result(adapter.unwritten_contents, 0)
          else
            cmd_result = adapter.read

            cmd_result.string = if cmd_result.exit_status.zero?
              cmd_result.ruby_object
            else
              cmd_result.ruby_object.message
            end

            cmd_result
          end
        end
      end

      # Stores +new_contents+ in memory until #save is called.
      #
      # @param [String] new_contents Contents to write to the file on #save.
      # @return [Rosh::Shell::PrivateCommandResult]
      def contents=(new_contents)
        echo_rosh_command new_contents

        current_contents = self.contents

        run_idempotent_command(new_contents == current_contents) do
          adapter.unwritten_contents = new_contents
          cmd_result = private_result(true, 0)
          update(:contents, cmd_result, current_shell.su?, from: current_contents, to: new_contents)

          cmd_result
        end
      end

      # @param [String] destination
      # @return [Rosh::FileSystem::File] The newly copied filed.
      def copy_to(destination)
        echo_rosh_command destination

        the_copy = current_host.fs[file: destination]

        matches = [
          -> { !the_copy.persisted? },
          -> { the_copy.size != self.size },
          -> { the_copy.contents != self.contents }
        ]

        run_idempotent_command(matches.any?(&:call)) do
          adapter.copy(destination)
        end
      end

      # @param [String] new_path
      # @return [Rosh::Shell::PrivateCommandResult]
      def hard_link_to(new_path)
        echo_rosh_command new_path

        new_link = current_host.fs[file: new_path]

        result = run_idempotent_command(new_link.persisted?) do
          adapter.link(new_path)
        end

        result || new_link
      end
      alias_method :link, :hard_link_to

      # @param [Fixnum] length
      # @param [Fixnum] offset
      # @return [Rosh::Shell::PrivateCommandResult]
      def read(length=nil, offset=nil)
        echo_rosh_command length, offset

        run_command do
          cmd_result = adapter.read(length, offset)
          cmd_result.string = cmd_result.ruby_object

          cmd_result
        end
      end

      def readlines(separator=$/)
        echo_rosh_command separator

        run_command do
          cmd_result = adapter.readlines(separator)
          cmd_result.string = cmd_result.ruby_object.join("\n")

          cmd_result
        end
      end

      def each_char(&block)
        echo_rosh_command

        run_command { adapter.each_char(&block) }
      end

      def each_codepoint(&block)
        echo_rosh_command

        run_command { contents.each_codepoint(&block) }
      end

      def each_line(separator=$/, &block)
        echo_rosh_command

        run_command { contents.each_line(separator, &block) }
      end

      def save
        echo_rosh_command

        previous_state = self.state

        run_idempotent_command(self.persisted?) do
          cmd_result = adapter.save

          if cmd_result.exit_status.zero?
            adapter.unwritten_contents.clear

            if previous_state == :transient
              persist(:exists?, cmd_result, current_shell.su?,
                from: false, to: true)
            elsif previous_state == :dirtied
              update(:dirtied?, cmd_result, current_shell.su?,
                from: true, to: false)
            end
          end

          cmd_result
        end
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

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
          :local_file
        else
          :remote_file
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
