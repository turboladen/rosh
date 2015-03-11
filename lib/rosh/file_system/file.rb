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
          log "State: #{state}"

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

      # Copies this File object to the +destination+.  If the copy was
      # successful and a block is given, yields the new File to the block; the
      # return value is the result of this command--not any internal commands.
      #
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

        match_result = matches.none?(&:call)
        log "copy_to matches result: #{match_result}"

        run_idempotent_command(match_result) do
          copy_result = adapter.copy(destination)

          if copy_result.exit_status.zero? && block_given?
            yield copy_result.ruby_object
          end

          copy_result
        end
      end

      # Hard links this File object to the +new_path+.  If the link creation was
      # successful and a block is given, yields the new File to the block; the
      # return value is the result of this command--not any internal commands.
      #
      # @param [String] new_path
      # @return [Rosh::Shell::PrivateCommandResult]
      def hard_link_to(new_path)
        echo_rosh_command new_path

        new_link = current_host.fs[file: new_path]

        run_idempotent_command(new_link.persisted?) do
          link_result = adapter.link(new_path)

          if link_result.exit_status.zero? && block_given?
            yield link_result.ruby_object
          end

          link_result || new_link
        end
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
        log "Previous state: #{previous_state}"

        run_idempotent_command(self.persisted?) do
          cmd_result = adapter.save

          if cmd_result.exit_status.zero?
            adapter.unwritten_contents.clear

            case previous_state
            when :transient
              persist(:exists?, cmd_result, current_shell.su?,
                from: false, to: true)
            when :dirtied
              persist(:dirtied?, cmd_result, current_shell.su?,
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

        type = if Rosh.environment.current_host.local?
          :local_file
        else
          :remote_file
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
